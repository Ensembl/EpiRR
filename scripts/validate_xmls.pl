#!/usr/bin/env perl

use warnings;
use strict;

use Pod::Usage;
use EpiRR::Schema;
use Getopt::Long;
use Carp;
use Cwd;
use DBI;
use DBD::Oracle;
use File::Find;
use File::Spec;
use File::Temp qw/ tempfile/;
use File::chdir;
use Path::Tiny;
use File::Basename;
use Log::Log4perl qw(:easy);
use XML::LibXML;
use autodie;
use List::MoreUtils qw(all);
use JSON::MaybeXS qw(encode_json decode_json);
use JSON::PP;
use feature qw(say);
use Data::Dumper;

$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Deepcopy = 1;

main();

sub main {
  my $self = bless({}, __PACKAGE__);
  $self->parse_options();
  $self->sql_oracle();
  $self->fetch_epirr_accessions();
  $self->filter_raw_data();
  $self->remove_xml_tsv_log_files() if $self->{opts}->{clean};
  $self->iterate();
  # defined ($self->{opts}->{json_dir}) ? $self->parse_json() : $self->filter_raw_data();

  exit;
}


# Check if experiment validates
# If not, extract and do vodoo
# Check if it has a sample
# Check if sample validates
# $self->{accs}->{$archive_name}->{$epirr_acc}->{$primary_accession}++;
sub iterate {
  my ($self) = @_;
  my $i = 0;
  my $accs = $self->{epirr_accessions};
  foreach my $archive (sort keys $accs){
    PROJECT:
    foreach my $project (sort keys $accs->{$archive}){
      foreach my $a ( @{$accs->{$archive}->{$project}} ){
        my ($exp_acc, $ihec) = @{$a};
        next unless ($ihec eq 'IHECRE00003421');
        DEBUG "------ Start ------";
        DEBUG "IHEC: $ihec";
        DEBUG "Experiment Acc: $exp_acc";
        my ($exp_xml, $samples) = $self->test_and_get_xmls($archive, $exp_acc, $ihec);
        
        # Figure out when this happens, 
       # next if( keys $self->{opts}->{accessions} and ! defined $self->{opts}->{accessions}->{$sample_acc} and !defined $self->{opts}->{accessions}->{$exp_acc} );
      
        $self->validate_experiment($ihec, $project, $exp_acc, $exp_xml);
        $self->validate_samples($ihec, $project, $samples, $archive);

        # ($err_e, $err_s)    = $self->validate_molecule($exp_xml, $sample_xml, $err_e, $err_s);
       
        if ($i == 2){$self->write_report($archive, $project);next PROJECT;}
        $i++;
      }
      $self->write_report($archive, $project);
      delete($self->{report}->{$project});
    }
  }
  $self->write_stats();
  
  #if( $self->{dbh}->{erapro}->ping ) {
    $self->{dbh}->{erapro}->disconnect
      or warn "Disconnection failed: $DBI::errstr\n";
  #}
}

sub test_and_get_xmls {
  my ($self, $archive, $exp_acc, $ihec) = @_;

  #warn "Data fetching terminated early by error: $DBI::errstr\n"  if $DBI::err;

  $self->{sth}->{lc($archive)}->{exp}->execute($exp_acc);
  my ($exp_xml) = $self->{sth}->{lc($archive)}->{exp}->fetchrow_array();
  DEBUG "Experiment XML\n$exp_xml";
  $self->test_xml($exp_xml, $archive, $exp_acc, $ihec);
 
  $self->{sth}->{lc($archive)}->{sample}->execute($exp_acc);
  my $samples = $self->{sth}->{lc($archive)}->{sample}->fetchall_hashref('SAMPLE_ID');
  DEBUG "Sample XML:\n".Dumper ($samples);
  
  for my $s (sort keys %{$samples}){
    my $acc = $samples->{$s}->{SAMPLE_ID};
    my $xml = $samples->{$s}->{SAMPLE_XML};
    $self->test_xml($xml, $archive, $acc, $ihec);
  }  
  return ($exp_xml, $samples);
  # Check if make any difference
  # $self->{sth}->{lc($archive)}->{exp}->finish();
  # $self->{sth}->{lc($archive)}->{sample}->finish();

}

sub test_xml {
  my ($self, $xml, $archive, $acc, $ihec ) = @_;

  # Loader complains if XML is malformed or string is empty
  # If neecessary, validate function can test against DTD
  my $dom = eval {XML::LibXML->load_xml(string => \$xml);};
  if ($@){
    say STDERR "Malformed XML. Archive: $archive, IHEC: $ihec, Accession: $acc";
  }
}


sub validate_experiment {
  my ($self, $ihec, $project, $acc, $xml) = @_;

  my $type = 'experiment';
  my $validator_args  = [$type]; 
  $self->validate_xml($ihec, $project, $validator_args, $acc, $xml, $type);
}

sub validate_samples {
  my ($self, $ihec, $project, $samples, $archive) = @_;

  my $type = 'sample';
  my $validator_args  = [$type];
  push @$validator_args, '-not-sra-xml-but-try' if( $archive eq 'ddbj' ); 

  for my $s (sort keys %{$samples}){
    my $acc = $samples->{$s}->{SAMPLE_ID};
    my $xml = $samples->{$s}->{SAMPLE_XML};
    $self->validate_xml($ihec, $project, $validator_args, $acc, $xml, $type );
  }  
}

sub validate_xml  {
  my ($self, $ihec, $project, $validator_args, $acc, $xml, $type) = @_;
  
  my ($validated, $error) = $self->validate($acc, $xml, $validator_args );
  DEBUG "Validated: $validated";
  DEBUG "Error: $error";
  if ($validated eq 'Failed'){
    push( @{$self->{report}->{$project}->{$ihec}}, $error);
  }
  # Hash to avoid duplicates
  $self->{stats}->{$type}->{$project}->{$validated}->{$acc}++;

}

# $type experiment or sample
# Check the XML with the validator. If the 
sub validate {
  my ($self, $accession, $xml, $validator_args) = @_;

  DEBUG "Validate: accession: $accession\tArgs: ".join "\t", @{$validator_args};
  my $work_dir  = $self->{opts}->{work_dir};

  my $file_xml      = $self->write_xml_file($accession, $xml);
  my $file_ver_xml  = File::Spec->catfile($work_dir, "$accession.versioned.xml");
  my ($validated, $error_log) = $self->run_validator($file_ver_xml, $file_xml, $validator_args);
  unlink($file_ver_xml) if(-e $file_ver_xml);
  unlink($file_xml);
  return($validated, $error_log);
}

sub run_validator {
  my ($self, $versioned_xml, $xml, $array_args) = @_; 
  
  # Validator can currently only run in IHEC directory
  local $CWD = $self->{opts}->{ihec_dir};
  DEBUG "CD to: $CWD";

  # DEBUG  ( caller(1) )[3] ."\tLine: ". ( caller(0) )[2];
  DEBUG "Versioned XML: $versioned_xml\tXML: $xml\tArgs:", join "\t", @{$array_args};
  # Remove whitespaces
  # add leading dash if it not exists
  for my $e (@{$array_args}) {
    $e =~ s/\s+//g;
    $e = "-$e" if($e !~ /^-/);
  }
  my $args      = join(' ', @$array_args);
  DEBUG "Validator arguments: $args";
  my $cfg_json  = $self->{opts}->{cfg_ihec_json};

  # Keep files for debuggin
  my $fh_out    = File::Temp->new( UNLINK => 0,  SUFFIX => '.out.epirr');
  my $file_stdout  = $fh_out->filename; 
  my $fh_err    = File::Temp->new( UNLINK => 0,  SUFFIX => '.err.epirr');
  my $file_stderr  = $fh_err->filename;
  my $fh_json   = File::Temp->new( UNLINK => 0,  SUFFIX => '.json.epirr');
  my $file_json = $fh_json->filename;
  DEBUG "Validator STDOUT: $file_stdout";
  DEBUG "Validator STDERR: $file_stderr";
  DEBUG "Validator JSON  : $file_json";

  my $cmd = "python -m version_metadata $args -overwrite-outfile -out:$versioned_xml -jsonlog:$file_json $xml >$file_stdout 2>$file_stderr";
  $self->run_cmd($cmd);
  
  my ($validated, $error) = $self->parse_validator_json(path($file_json));
  DEBUG "Validated: $validated";
  DEBUG "Validator Error: $error";
  unlink($file_stderr);
  unlink($file_stdout);
  unlink($file_json);
  return ($validated, $error);
}

# {
#     "ENCSR993QER_experiment.no_MOLECULE_plusURI.xml": [
#         {
#             "ENCSR522UKJ": {
#                 "error_type": "__prevalidation__",
#                 "errors": [
#                     "missing",
#                     [
#                         "experiment_ontology_curie",
#                         "extraction_protocol_sonication_cycles",
#                         "extraction_protocol_type_of_sonicator"                                                                                                                                            
#                     ]
#                 ],
#                 "version": "1.1"
#             }
#         },
#         { 
#             "ENCSR522UKJ": {
#                 "errors": [], 
#                 "ok": true,
#                 "version": "1.0" 
#             }         
#         }             
#     ]                 
# }
sub parse_validator_json {
  my ($self, $file) = @_;

  my $content = $file->slurp;
  DEBUG "Validator JSON:\n$content";
  my $j = '';
  eval { $j = decode_json($content) };
  if ($@){
    die "invalid json. error: $@\n";
  }

  my $validated = 'Validated';
  my $error = {};
  foreach my $file_name (keys %{$j} ){
    foreach my $k (@{$j->{$file_name}}){
      foreach my $acc (keys %{$k}){
        next if $k->{$acc}->{ok} eq 'true';
        $validated = 'Failed';   
        my $version = $k->{$acc}->{version};
        $error->{$acc}->{$version} = [$k->{$acc}->{errors}];                                                                                                                                              
      }   
    }   
  }
  DEBUG Dumper($error);
  my $error_string = $self->stringify_error($error);

  return($validated, $error_string);
}

#   'DRX036828' => {
#     '1.0' => [
#       '__mising_both__:__experiment_ontology_uri+experiment_type__'
#     ],
#     '1.1' => [
#       '__mising_both__:__experiment_ontology_curie+experiment_type__'
#     ]
#   }
# }
sub stringify_error {
  my ($self, $error) = @_;

  my $err_str = '';
  foreach my $acc (sort keys %{$error}) {
    $err_str .= $acc;
    foreach my $version ( sort keys %{$error->{$acc}} ){
      my $errors = join("\n\t", @{$error->{$acc}->{$version}});
      $err_str .= "\n\t$version\t$errors";
    }
  }
  DEBUG "JSON error stringify:\n$err_str";
 
 return $err_str;

}



sub validate_molecule {
  die "Needs updating";
  my ($self, $exp_xml, $sample_xml, $err_e, $err_s) = @_;

  if ( $exp_xml !~ m!<TAG>MOLECULE</TAG>!o and $sample_xml !~ m!<TAG>MOLECULE</TAG>!o ) {
    $err_e = defined($err_e) ? "MOLECULE not defined. $err_e" : "MOLECULE not defined.";

    if (!$self->{opts}->{legacy}) {
      $err_e = defined($err_e) ? "MOLECULE needs to be defined in Experiment. $err_e" : "MOLECULE not defined.";
    }
  }

  if ( (!$self->{opts}->{legacy}) and $sample_xml =~ m!<TAG>MOLECULE</TAG>!o ){
      $err_e = defined($err_e) ? "MOLECULE needs to be defined in Experiment, not in Sample. $err_e" : "MOLECULE needs to be defined in Experiment, not in Sample.";
      $err_s = defined($err_s) ? "MOLECULE needs to be defined in Experiment, not in Sample. $err_s" : "MOLECULE needs to be defined in Experiment, not in Sample.";
  }

 #print "Within the validate_molecule subroutine the errors are:\nEXPERIMENT: $err_e\nSAMPLE: $err_s\n";

 return ($err_e, $err_s);

}

sub write_report {
  my ($self, $archive, $project) = @_;

  my $dir      = $self->{opts}->{work_dir};
  my $filename = $archive.'_'."$project.".time.'.tsv';

  my $report = File::Spec->catfile($dir, $filename);
  
  open my $fh, '>', $report or croak "Could not open $report: $!";
    INFO "Writing $report";
    # say $fh "IHEC accession\tProject\tArchive accession\tValidation\tErrors";
    for my $ihec (sort keys %{ $self->{report}->{$project} } ){
      for my $error (@{ $self->{report}->{$project}->{$ihec} }){
        say $fh "$error";
      }
    }
  close($fh);
}

sub write_stats {
  my ($self) = @_;

  my $stats = File::Spec->catfile($self->{opts}->{work_dir}, 'overview.tsv');
  open my $fh, '>', $stats or croak "Could not open $stats: $!";
  INFO "Writing Statistics: $stats";
    say $fh "Project\tType\tValidated\tFailed";
    foreach my $type (sort keys %{ $self->{stats} }){
      foreach my $project (sort keys %{ $self->{stats}->{$type} } ){
        foreach my $flag (sort keys %{ $self->{stats}->{$type}->{$project} } ){
          my $validated = keys %{$self->{stats}->{$type}->{$project}->{'Validated'}};
          my $failed    = keys %{$self->{stats}->{$type}->{$project}->{'Failed'}};
          # my $validator_failure = keys %{$self->{stats}->{$type}->{$project}->{'Validator Failure'}};
 
          $validated  = 0 if(!defined $validated);
          $failed     = 0 if(!defined $failed);
          # $validator_failure = 0 if(!defined $validator_failure); 

          say $fh "$project\t$type\t$validated\t$failed";
        }
      }
    } 
  close($fh);
}

# sub report {
#   my ($self, $ihec, $project, $acc, $error, $type ) = @_;
#   DEBUG "$ihec, $project, $acc, $error, $type";
#   my $flag; 
#   if ( defined($error) and $error =~ m/Check manually/){
#     $flag = 'Validator Failure';
#   } 
#   elsif ( defined($error) ){
#     $flag  = 'Failed';
#   }
#   else{
#     $error = '';
#     $flag = 'Validated';
#   }
#   my $tmp = "$ihec\t$project\t$acc\t$flag\t$error"; 
#   push( @{$self->{report}->{$project}}, $tmp);

#   $self->{stats}->{$type}->{$project}->{$flag}->{$acc}++;
# }

sub filter_raw_data {
  my ($self) = @_;

  my %archives = map { $_ => 1 } @{$self->{opts}->{archive}};
  my %projects = map { $_ => 1 } @{$self->{opts}->{project}};
  my $accessions = $self->{epirr_accessions};
  # say Dumper($accessions);die;
  
  foreach my $archive (sort keys %{$accessions}) {
    foreach my $project (sort keys %{$accessions->{$archive}}){
      delete $self->{epirr_accessions}->{project} unless (exists $projects{$project});
    }
    delete $self->{epirr_accessions}->{$archive} unless (exists $archives{$archive});
  }
}

sub write_xml_file {
  my ($self, $accession, $xml) = @_;

  my $file = File::Spec->catfile($self->{opts}->{work_dir}, "$accession.xml");
  DEBUG "write_xml_file: file: $file";
  return($file) if(-e $file);
  open my $fh, '>', $file;
    binmode($fh, ":utf8");
    print $fh $xml;
  close $fh;
  DEBUG "write_xml_file: Finished writing";
  return($file);
}




sub run_cmd {
  my ($self, $cmd) = @_;

  die "Nothing passed to execute" if(!$cmd);
  DEBUG $cmd;
  system($cmd);
  if ($? == -1) {
    print "failed to execute: $!\n";
  }
  elsif ($? & 127) {
    printf "child died with signal %d, %s coredump\n",
    ($? & 127),  ($? & 128) ? 'with' : 'without';
  }
  else {
   # Success, but only blows up the log file.
    # DEBUG printf "child exited with value %d\n", $? >> 8;
  }
}

sub sql_oracle {
  my ($self) = @_;

  my $dsn = $ENV{ERA_DSN};
  my $user = $ENV{ERA_USER};
  my $pass = $ENV{ERA_PASS};

  my $dbh = DBI->connect( $dsn, $user, $pass, 
    { 'RaiseError' => 1, 'PrintError' => 0 } ) or croak "Could not connect: $!";
  INFO "Connected to DSN: $dsn";
  #default is 80, far to short for the XML records
  $dbh->{LongReadLen} = 66600;

  $self->{dbh}->{erapro} = $dbh;

  my $sth;
  $sth = $dbh->prepare(' 
    SELECT xmltype.getclobval(experiment_xml) 
    FROM experiment 
    WHERE experiment_id = ? 
    AND ega_id IS NULL
  ');
  $self->{sth}->{ena}->{exp} = $sth;
  # Same for DDBJ, different key to have automated match with archive name
  $self->{sth}->{ddbj}->{exp} = $sth;

  $sth = $dbh->prepare('
    SELECT sample_id, xmltype.getclobval(sample_xml) as sample_xml 
    FROM sample 
    JOIN experiment_sample USING (sample_id) 
    WHERE experiment_id = ?
  ');

  $self->{sth}->{ena}->{sample} = $sth;
  $self->{sth}->{ddbj}->{sample} = $sth;

  $sth = $dbh->prepare('
    SELECT xmltype.getclobval(experiment_xml) 
    FROM experiment WHERE ? 
    IN (experiment_id, ega_id) 
    AND ega_id IS NOT NULL
  ');

  $self->{sth}->{ega}->{exp} = $sth;

  $sth = $dbh->prepare('
    SELECT sample.sample_id, xmltype.getclobval(sample_xml) 
    FROM sample 
    JOIN experiment_sample ON sample.sample_id = experiment_sample.sample_id 
    JOIN experiment ON experiment.experiment_id = experiment_sample.experiment_id 
    WHERE  ? IN (experiment.experiment_id, experiment.EGA_ID) 
    AND experiment.EGA_ID IS NOT NULL
  ');
  $self->{sth}->{ega}->{sample} = $sth;
}

sub fetch_epirr_accessions {
  my ($self) = @_;

  my $dsn  = $ENV{EPIRR_TEST_DSN};
  my $user = $ENV{EPIRR_TEST_USER};
  my $pass = $ENV{EPIRR_TEST_PASS};
  INFO "DSN: $dsn\tUser: $user\tPW: $pass";
  my $dbh = DBI->connect( $dsn, $user, $pass, 
    { 'RaiseError' => 1, 'PrintError' => 0 } ) or croak "Could not connect: $!";
  INFO "Connected to DSN: $dsn as $user"; 

  my $archive = "'".join("','", @{$self->{opts}->{archive}})."'";
  my $project = "'".join("','", @{$self->{opts}->{project}})."'";

  my $sql = ("
    SELECT DISTINCT(primary_accession), archive.name,  project.name, dataset.accession 
    FROM raw_data 
    JOIN archive          USING(archive_id) 
    JOIN dataset_version  USING (dataset_version_id) 
    JOIN dataset          USING (dataset_id) 
    JOIN project          USING(project_id) 
    WHERE is_current = 1 
    AND archive.name IN ($archive)
    AND project.name IN ($project)
  ");

  INFO $sql;
  
  my $sth = $dbh->prepare($sql);
  $sth->execute();

  while ( my ($acc, $archive, $project, $ihec)  = $sth->fetchrow_array ){
    push @{ $self->{epirr_accessions}->{lc($archive)}->{lc($project)} }, [$acc, $ihec];  
  }

  $dbh->disconnect
    or warn "Disconnection from EpiRR database failed: $DBI::errstr\n";
  DEBUG "EpiRR accessions: " . Dumper $self->{epirr_accessions};
}

#  errs.sample.1.CKH.ERS.Sep-10-2018-22.22.26.log
sub remove_xml_tsv_log_files {
   my ($self) = @_;
   my $dir = $self->{opts}->{work_dir};
   my @files = glob ("$dir/*.xml $dir/*.tsv $dir/*.log");
   if (scalar @files > 0){  
    unlink @files or croak "Could not delete files in Working Dir: $!";
  }
}

sub parse_options {
  my ($self) = @_;

  # undef so missing arguments are caught.
  # Add option accessions for filtering. Store as hash
  my $opts = {
    cfg_epirr     => 'EpiRR::Config::Production',
    cfg_ihec_json => $ENV{CFG_IHEC_JSON},
    work_dir      => $ENV{WORK_DIR},
    ihec_dir      => $ENV{IHEC_DIR},
    archive       => [],
    project       => [],
    accessions    => [],
    json_dir      => undef,
  };

  my $splitter = sub {
    my ($name, $val) = @_;
    push @{$opts->{$name}}, split q{,}, $val;
  };
  
  GetOptions($opts,
    'cfg_epirr=s',
    'cfg_ihec_json=s',
    'work_dir=s',
    'ihec_dir=s',
    'archive=s@' => $splitter,
    'project=s@' => $splitter,
    'accessions=s@' => $splitter,
    'json_dir=s',
    'legacy',
    'debug',
    'clean',
    'help',
    'verbose',
  ) or pod2usage(-msg => 'Misconfigured options given', -verbose => 1, -exitval => 1);
  pod2usage(-verbose => 1, -exitval => 0) if $opts->{help};

  my @required = qw (cfg_epirr cfg_ihec_json work_dir ihec_dir archive);
  die pod2usage() unless all { defined $opts->{$_} } @required;

  Log::Log4perl->easy_init($INFO);
  Log::Log4perl->easy_init($DEBUG) if $opts->{debug} ;

  $self->check_required_directories_modules($opts);
  $self->check_and_set_projects($opts);
  $self->check_and_set_archives($opts);

  # Could not find a way to directly map from options
  my %tmp = map { $_ => 1 } @{$opts->{accessions}};
  $opts->{accessions} = \%tmp;

  if(defined $opts->{json_dir}){
    die "Using json files in directory not implemented";
  }

  DEBUG "All options: " . Dumper $opts;
  
  return $self->{opts} = $opts;
}

sub check_required_directories_modules {
  my ($self, $opts) = @_;

  croak('"-work_dir '. $opts->{work_dir} .'" not found') unless ( -d $opts->{work_dir} );
  croak('"-ihec_dir '. $opts->{ihec_dir} .'" not found') unless ( -d $opts->{ihec_dir} );
  croak('"-cfg_ihec_json '. $opts->{cfg_ihec_json} .'" not found') unless ( -e $opts->{cfg_ihec_json} );
  
  eval ('require ' . $opts->{cfg_epirr} ) or croak('-cfg_epirr '. $opts->{cfg_epirr} . 'Cannot load module ' . $@);

  INFO 'Working Directory:' . $opts->{work_dir};
  INFO 'IHEC Directory:'    . $opts->{ihec_dir};
  INFO 'Validator Config: ' . $opts->{cfg_ihec_json}


}

sub check_and_set_projects {
  my ($self, $opts) = @_;

  $opts->{valid_projects} = [
      'amed-crest','blueprint','ceehrc','deep','encode',
      'epp','gis','hipsci','korea epigenome project (knih)','nih roadmap epigenomics'
  ];

  # If no projects are specified, test all
  if(scalar @{$opts->{project}} == 0 or !defined $opts->{project}){
    $opts->{project} = $opts->{valid_projects};
  }

  # Used as hash keys later, need to be all lowercase
  $_ = lc for @{$opts->{project}};

  my %valid = map { $_ => 1 }  @{ $opts->{valid_projects} }; 
  foreach my $p  (@{$opts->{project}}) {
    if( !exists($valid{$p}) ){
      croak ">$p< is not a valid project. Valid projects are: " . join "--", @{$opts->{valid_projects}};
    }
  }
  
  INFO 'Projects to process: ' . join "--", @{$opts->{project}};

}

sub check_and_set_archives {
  my ($self, $opts) = @_;

  $opts->{valid_archives} = [qw (ddbj ega ena)]; 
  
  if(scalar @{$opts->{archive}} == 0 or !defined $opts->{archive} ){
    $opts->{archive} = $opts->{valid_archives}; 
  }

  $_ = lc for @{$opts->{archive}};

  my %valid = map { $_ => 1 }  @{ $opts->{valid_archives} }; 
  foreach my $a  (@{$opts->{archive}}) {
    if( !exists($valid{$a}) ){
      croak "'>$a< is not a valid archive. Valid archives are: " . join "--", @{$opts->{valid_archives}};
    }
  }
  INFO 'Archives to process: ' . join "--", @{$opts->{archive}};
}

sub check_and_set_json_dir {
  my ($self, $opts) = @_;

  INFO "-json_dir set. Removing -archive, -project, -accessions restriction";
  my $d = $opts->{json_dir};
  croak "-json_dir $d not found" if(!-d $d); 
  $opts->{archive} = [];
  $opts->{project} = [];
  $opts->{accessions} = [];

}


sub parse_refepi_json {
  die "Stub, not tested";
  my ($self) = @_;
  INFO "Parsing JSON files";

  my $dir = $self->{opts}->{json_dir};
  my @files =  glob("$dir/*.refepi.json");
  croak "No *.refepi.json files in $dir" if(scalar @files == 0);
  foreach my $file_path (@files) {
    DEBUG "Processing $file_path";
    my $file = read_file($file_path);
    my $json = decode_json($file);
    my $project = $json->{project};
    my $basename = basename($file_path);
    my $epirr_acc = defined($json->{accession}) ? $json->{accession}  : "new_$basename" ;

    for my $rd (@{$json->{raw_data}}){
      $self->{accs}->{$rd->{archive}}->{$epirr_acc}->{$rd->{primary_id}}++;
      $self->{acc2project}->{$rd->{primary_id}} = $project;
    }
  }
}


=head1 NAME

  validate_xmls

=head1 SYNOPSIS

  validate_xmls.pl  -cfg_epirr  EpiRR::Config::Production
                    -work_dir $HOME/validate_dir
                    -cfg_ihec_json $HOME/src/ihec-ecosystems/version_metadata/config.json 
                    -ihec_dir $HOME/src/hec-ecosystems/version_metadata


=head1 DESCRIPTION

This script will iterate through XML files and run the IHEC validator on them.

=head1 PARAMETERS

=over 8

=item B<-cfg_epirr>

Epirr config module, eg EpiRR::Config::Production'

=item B<-cfg_ihec_json>

Configuration file used by the IHEC validator. It is advised to have absolute path in 
the config file. 

=item B<-work_dir>

Directory where temporary files and summary.tsv will be created

=item B<-ihec_dir>

IHEC repository containing the validator (__main__.py) and review.py 

=item B<-archive>

List of archives to retrieve from database. If not set, all archives are processed. 
Please note that DDBJ is not accessible for us at the moment. 

=item B<-project>

List of projects to process. If not set, all projects are processed.

=item B<-accessions>

List of accessions to process. If not set, all accessions are processed

=item B<-json_dir>

Directory containing JSON files in IHEC format. All accessions found will be processed.

=item B<-legacy>

Set if the examples examining are submitted before 25 May 2018. MOLECULE can also be in Sample. 
After it has to be in experiment.

=item B<-clean>

Removes all *.tsv and all *.xml files in -work_dir

=item B<-debug>

Debug mode

=back

=cut



