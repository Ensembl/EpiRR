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
use Path::Tiny;
use File::Basename;
use Log::Log4perl qw(:easy);
use autodie;
use List::MoreUtils qw(all);
use JSON::MaybeXS qw(encode_json decode_json);
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
        $self->{sth}->{lc($archive)}->{exp}->execute($exp_acc);
        my ($exp_xml) = $self->{sth}->{lc($archive)}->{exp}->fetchrow_array();
        #warn "Data fetching terminated early by error: $DBI::errstr\n"
        #  if $DBI::err;
        $self->{sth}->{lc($archive)}->{exp}->finish();
        
        $self->{sth}->{lc($archive)}->{sample}->execute($exp_acc);
        my ($sample_acc, $sample_xml) = $self->{sth}->{lc($archive)}->{sample}->fetchrow_array();
        #warn "Data fetching terminated early by error: $DBI::errstr\n"
        #  if $DBI::err;      
        $self->{sth}->{lc($archive)}->{sample}->finish();

        next if( keys $self->{opts}->{accessions} and ! defined $self->{opts}->{accessions}->{$sample_acc} and !defined $self->{opts}->{accessions}->{$exp_acc} );
        #print "Looking at @{$a} from $archive for project: $project.\n";
      
        my @validator_args = qw( experiment ); 
        my $err_e   = $self->validate( $exp_acc, $exp_xml, \@validator_args );
        @validator_args = qw( sample );
        push @validator_args, '-not-sra-xml-but-try' if( $archive eq 'ddbj' ); 
        my $err_s   = $self->validate( $sample_acc, $sample_xml, \@validator_args );
        ($err_e, $err_s) = $self->validate_molecule($exp_xml, $sample_xml, $err_e, $err_s);
       
        #print "Within the iterate subroutine the errors are:\nEXPERIMENT: $err_e\nSAMPLE: $err_s\n";

        $self->report($ihec, $project, $exp_acc, $err_e, 'experiment');
        $self->report($ihec, $project, $sample_acc, $err_s, 'sample');
        # if ($i == 3){$self->write_report($archive, $project);next PROJECT;}
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

# $type experiment or sample
# Check the XML with the validator. If the 
sub validate {
  my ($self, $accession, $xml, $validator_args) = @_;

  # INFO "Validating: $type - $accession";
  # DEBUG "Accession: $accession\tObject: ".ref $object;
  my $work_dir  = $self->{opts}->{work_dir};

  my $file_xml      = $self->write_xml_file($accession, $xml);
  my $file_ver_xml  = File::Spec->catfile($work_dir, "$accession.versioned.xml");
  my $error_log = $self->run_py($file_ver_xml, $file_xml, $validator_args);
  my $validated = defined($error_log) ? 'Failed' : 'Validated';
  INFO "$accession Validation $validated"; 

  unlink($file_ver_xml) if(-e $file_ver_xml);
  unlink($file_xml);
  
  return($error_log);
}

sub validate_molecule {
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

#    $self->{accs}->{$archive_name}->{$epirr_acc}->{$primary_accession}++;
sub parse_json {
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

sub write_report {
  my ($self, $archive, $project) = @_;

  my $dir = $self->{opts}->{work_dir};
  my $filename = $archive.'_'."$project.".time.'.tsv';

  my $report = File::Spec->catfile($dir, $filename);
  open my $fh, '>', $report or croak "Could not open $report: $!";
  INFO "Writing $report";
    say $fh "IHEC accession\tProject\tArchive accession\tValidation\tErrors";
    for my $line ( @{ $self->{report}->{$project} } ){
      say $fh $line;
    }
  close($fh);
}

sub write_stats {
  my ($self) = @_;

  my $report = File::Spec->catfile($self->{opts}->{work_dir}, 'overview.tsv');
  open my $fh, '>', $report or croak "Could not open $report: $!";
  INFO "Writing $report";
    say $fh "Project\tType\tValidated\tFailed\tValidator Issue";
    foreach my $type (sort keys %{ $self->{stats} }){
      foreach my $project (sort keys %{ $self->{stats}->{$type} } ){
        foreach my $flag (sort keys %{ $self->{stats}->{$type}->{$project} } ){
          my $true              = keys %{$self->{stats}->{$type}->{$project}->{'Validated'}};
          my $false             = keys %{$self->{stats}->{$type}->{$project}->{'Failed'}};
          my $validator_failure = keys %{$self->{stats}->{$type}->{$project}->{'Validator Failure'}};
 
          $true              = 0 if(!defined $true);
          $false             = 0 if(!defined $false);
          $validator_failure = 0 if(!defined $validator_failure); 

          say $fh "$project\t$type\t$true\t$false\t$validator_failure";
        }
      }
    } 
  close($fh);
}

sub report {
  my ($self, $ihec, $project, $acc, $error, $type ) = @_;

  my $flag; 
  if ( defined($error) and $error =~ m/Check manually/)
  {
    $flag = 'Validator Failure';
  } elsif ( defined($error) ){
    $flag  = 'Failed';
  }
  else{
    $error = '';
    $flag = 'Validated';
  }
  my $tmp = "$ihec\t$project\t$acc\t$flag\t$error"; 
  push( @{$self->{report}->{$project}}, $tmp);

  $self->{stats}->{$type}->{$project}->{$flag}->{$acc}++;
}

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
  return if(-e $file);
  open my $fh, '>', $file;
    binmode($fh, ":utf8");
    print $fh $xml;
  close $fh;

  return($file);
}

sub run_py {
  my ($self, $file1, $file2, $array_args) = @_; 
  # DEBUG  ( caller(1) )[3] ."\tLine: ". ( caller(0) )[2];
  TRACE "File1: $file1\tFile2: $file2\tArgs:", join "\t", @{$array_args};
  # Remove whitespaces
  # add leading dash if it not exists
  for my $e (@{$array_args}) {
    $e =~ s/\s+//g;
    $e = "-$e" if($e !~ /^-/);
  }
  my $args     = join(' ', @$array_args);
  my $py_main  = $self->{py_main};
  my $cfg_json = $self->{opts}->{cfg_ihec_json};

  my $fh_out   = File::Temp->new( UNLINK => 1,  SUFFIX => '.out.epirr');
  my $file_out = $fh_out->filename;
  my $fh_err   = File::Temp->new( UNLINK => 1,  SUFFIX => '.err.epirr');
  my $file_err = $fh_err->filename;
   
  my $cmd = "python $py_main $args -overwrite-outfile -config:$cfg_json -out:$file1 $file2 >$file_out 2>$file_err";
  $self->run_cmd($cmd);

  my $err = path($file_err)->slurp;
  my $out = path($file_out)->slurp;
  my $err_log = undef;
  if( $out =~ /validated: 0/ and $out =~ /failed: 1/ ){
    if($err =~ /#__validationFailuresFound: see (\S*)/){
      $err_log = path($1)->slurp;
      chomp($err_log);
      unlink(path($1));
    }
    else{
      croak "Not validated, but no error file found $out\n $err";
    }
  } elsif ( $out !~ /validated:/ ) {
    $err_log = "Unexpected failure of validator. Check manually."
  }
    
  return $err_log;
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
    SELECT sample_id, xmltype.getclobval(sample_xml) 
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
    JOIN archive USING(archive_id) 
    JOIN dataset_version USING (dataset_version_id) 
    JOIN dataset USING (dataset_id) 
    JOIN project USING(project_id) 
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

  #Sanity Checks
  croak('"-work_dir '. $opts->{work_dir} .'" not found') unless ( -d $opts->{work_dir} );
  croak('"-ihec_dir '. $opts->{ihec_dir} .'" not found') unless ( -d $opts->{ihec_dir} );
  croak('"-cfg_ihec_json '. $opts->{cfg_ihec_json} .'" not found') unless ( -e $opts->{cfg_ihec_json} );
  
  eval ('require ' . $opts->{cfg_epirr} ) or croak('-cfg_epirr '. $opts->{cfg_epirr} . 'Cannot load module ' . $@);
  
  # Required 
  $self->{py_main}    = File::Spec->catfile($opts->{ihec_dir}.'__main__.py');
  croak "Could not find ".$self->{py_main}." in ihec_dir [" . $opts->{ihec_dir} ."]" if(!-e $self->{py_main});
  $self->{py_review}  = File::Spec->catfile($opts->{ihec_dir}.'review.py');
  croak "Could not find review.py in ihec_dir [" . $opts->{ihec_dir} ."]" if(!-e $self->{py_review});

  # Projects in EpiRR. 
  $opts->{valid_projects} = [
      'amed-crest','blueprint','ceehrc','deep','encode',
      'epp','gis','hipsci','korea epigenome project (knih)','nih roadmap epigenomics'
  ];

  # These are the projects available through ERA DB
  $opts->{valid_archives} = [qw (ddbj ega ena)]; 
  
  if(scalar @{$opts->{archive}} == 0 or !defined $opts->{archive} ){
    $opts->{archive} = $opts->{valid_archives}; 
  }
  
  if(scalar @{$opts->{project}} == 0 or !defined $opts->{project}){
    $opts->{project} = $opts->{valid_projects};
  }
  # Used as hash keys later, need to be all lowercase
  $_ = lc for @{$opts->{archive}};
  $_ = lc for @{$opts->{project}};

  my %valid = map { $_ => 1 }  @{ $opts->{valid_archives} }; 
  foreach my $tmp  (@{$opts->{archive}}) {
    if( !exists($valid{$tmp}) ){
      croak "'>$tmp< is not a valid archive. Valid archives are: " . join "--", @{$opts->{valid_archives}};
    }
  }
  
  %valid = map { $_ => 1 }  @{ $opts->{valid_projects} }; 
  foreach my $tmp  (@{$opts->{project}}) {
    if( !exists($valid{$tmp}) ){
      croak ">$tmp< is not a valid project. Valid projects are: " . join "--", @{$opts->{valid_projects}};
    }
  }

  # Could not find a way to directly map from options
  my %tmp = map { $_ => 1 } @{$opts->{accessions}};
  $opts->{accessions} = \%tmp;

  if(defined $opts->{json_dir}){
    INFO "-json_dir set. Removing -archive, -project, -accessions restriction";
    $opts->{archive} = [];
    $opts->{project} = [];
    $opts->{accessions} = [];
    my $d = $opts->{json_dir};
    croak "-json_dir $d not found" if(!-d $d); 
  }

  # Used frequently, still should probably be defined somewhere else
  # $opts->{logs} = File::Spec->catfile(getcwd, 'errs.[experimentsample]*.log');
  # my $dir = File::Spec->catdir($opts->{work_dir},time);

  INFO 'Working Directory:' . $opts->{work_dir};
  INFO 'Archives to process: ' . join "--", @{$opts->{archive}};
  INFO 'Projects to process: ' . join "--", @{$opts->{project}};
  # INFO Dumper $opts;die;
  return $self->{opts} = $opts;
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



