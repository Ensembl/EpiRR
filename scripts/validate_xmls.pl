

=head1 NAME

  validate_xmls

=head1 SYNOPSIS

  validate_xmls.pl  -cfg_epirr  EpiRR::Config::Production
                    -work_dir $HOME/validate_dir
                    -cfg_ihec_json $HOME/src/ihec-ecosystems/version_metadata/config.json 
                    -dir_ihec $HOME/src/hec-ecosystems/version_metadata


=head1 DESCRIPTION

This script will iterate through XML files and run the IHEC validator on them.

=head1 PARAMETERS

=over 8

=item B<-cfg_epirr>

Epirr config module, eg EpiRR::Config::Production'


=item B<-work_dir>

Directory where temporary files will be created

=item B<-cfg_ihec_json>

Configuration file used by the IHEC validator

=item B<-dir_ihec>

IHEC repository containing the validator

=back

=cut

use warnings;
use strict;

use Pod::Usage;
use EpiRR::Schema;
use Getopt::Long;
use Carp;
use Cwd;
use File::Find;
use File::Spec;
use File::Slurp;
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
  $self->remove_xml_tsv_files() if $self->{opts}->{clean};
  $self->open_report();
  $self->get_services_accessors();
  defined ($self->{opts}->{json_dir}) ? $self->parse_json() : $self->filter_raw_data();
  DEBUG Dumper($self->{accs});
  $self->iterate();
  $self->close_fh($self->{fh_report});
}

# Check if experiment validates
# If not, extract and do vodoo
# Check if it has a sample
# Check if sample validates
# $self->{accs}->{$archive_name}->{$epirr_acc}->{$primary_accession}++;
sub iterate {
  my ($self) = @_;
  
  $self->remove_error_logs();
  my $tmp = $self->{accs};
  foreach my $archive (sort keys %{$tmp} ) {
    foreach my $epirr (sort keys $tmp->{$archive}) {
      foreach my $acc (sort keys $tmp->{$archive}->{$epirr}) {
        my $project = $self->{acc2project}->{$acc};
        my ($exp_row, $exp)       = $self->fetch_xml_experiment($archive, $acc);
        my ($sample, $sample_xml) = $self->fetch_xml_sample($exp, $archive);
        my $err_e                 = $self->validate('experiment' ,$acc, $exp_row->[2], $exp);
        my $err_s                 = $self->validate('sample', $acc, $sample_xml, $sample);
        $self->validate_molecule($exp, $sample, $err_e, $err_s);
        $self->write_report($epirr, $project, $acc, $err_e);
        $self->write_report($epirr, $project, $exp->sample_id(), $err_s);
      }
    }
  }
}

#    $self->{accs}->{$archive_name}->{$epirr_acc}->{$primary_accession}++;
sub parse_json {
  my ($self) = @_;
  INFO "Parsing JSON files";

  my $dir = $self->{opts}->{json_dir};
  my @files =  glob("$dir/*.refepi.json");
  croak "No *.refepi.json files in $dir" if(scalar @files == 0);
  foreach my $file_path (@files) {
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

# $type experiment or sample
sub validate {
  my ($self, $type, $accession, $xml, $object) = @_;

  INFO "Validating: $type";
  DEBUG "Accession: $accession\tObject: ".ref $object;
  my $work_dir  = $self->{opts}->{work_dir};

  my $file_xml      = $self->write_xml_file($accession, $xml);
  my $file_ver_xml  = File::Spec->catfile($work_dir, "$accession.versioned.xml");

  my $validated = $self->run_py([$type], $file_ver_xml, $file_xml);
  INFO "$accession $validated"; 
  unlink($file_ver_xml);
  my $unlinked = $self->remove_error_logs();
  
  #Change to array, empty array can be reported as "None"
  my $validation_errors = undef;

  if ($validated eq 'Failed'){
    INFO "Running Extract";
    DEBUG "File Version: $file_ver_xml\t File XML: $file_xml";
    $self->run_py([$type, 'extract'], $file_ver_xml, $file_xml);
    my $file_ext_json = File::Spec->catfile($work_dir, "$accession.xml.extracted.json");
    my ($fh_tmp, $file_tmp) = tempfile();

    INFO "Running Review";
    my $cmd = "python " .$self->{py_review}. " -$type $file_ext_json > $file_tmp";
    $self->run_cmd($cmd);

    my $errors = path($file_tmp)->slurp_utf8;
    chomp($errors);
    $validation_errors .= $errors;
    unlink($file_ext_json);
  }
  

  unlink($file_xml);
  return($validation_errors);
}

# David B: What was decided is that for legacy (already submitted) data, we will accept a MOLECULE 
# field either in SAMPLE or in EXPERIMENT. Any data coming in the future will have to 
# follow the new spec, which is to have MOLECULE in EXPERIMENT objects.
sub validate_molecule {
  my ($self, $experiment, $sample, $err_e, $err_s) = @_;

  if ( !$experiment->get_meta_data('molecule') and !$sample->get_meta_data('molecule') ) {
    $err_e .= 'MOLECULE not defined';
  }

  if(!$self->{opts}->{legacy}) {
    if (!$experiment->get_meta_data('molecule') or $sample->get_meta_data('molecule') ){
      $err_e .= "MOLECULE needs to be defined in Experiment, not in Sample";
      $err_s .= "MOLECULE needs to be defined in Experiment, not in Sample";
    }
  }
}
sub remove_xml_tsv_files {
   my ($self) = @_;
   my $dir = $self->{opts}->{work_dir};
   my @files = glob ("$dir/*.xml $dir/*.tsv");
   if (scalar @files > 0){  
    unlink @files or croak "Could not delete files in Working Dir: $!";
  }
}

sub open_report {
  my ($self) = @_;
  my $report_file_name = File::Spec->catfile($self->{opts}->{work_dir}, 'summary'.time.'.tsv');

  open my $fh_report, '>', $report_file_name or croak "Could not open $report_file_name: $!";
  say $fh_report "EpiRR accession\tProject name\tExperiment/Sample ID\tValidates?\tErrors";

  $self->{fh_report} = $fh_report;
}

sub write_report {
  my ($self, $epirr, $project, $acc, $err ) = @_;

  my ($error, $flag) = ('','True'); 
  if ( defined($err) ){
    $error = $err;
    $flag  = 'False';
  }

  say { $self->{fh_report} } "$epirr\t$project\t$acc\t$flag\t$error";
}

sub close_fh {
  my ($self, $fh) = @_;

  close($fh);
}

sub filter_raw_data {
  my ($self) = @_;

  my %archives = map { $_ => 1 } @{$self->{opts}->{archive}};
  my @all_raw_data = $self->{database_service}->raw_data->all;

  foreach my $raw_data(@all_raw_data){
    my $archive_name      = $raw_data->archive->name ;
    my $primary_accession = $raw_data->primary_accession;
    my $epirr_acc         = $raw_data->dataset_version->dataset->accession;
    my $project_name      = $raw_data->dataset_version->dataset->project->name;

    next unless (defined $archives{$archive_name});
    next unless ($raw_data->dataset_version->is_current);
    if(scalar keys %{$self->{opts}->{accessions}} >0){
      next unless (exists $self->{opts}->{accessions}->{$primary_accession});
    }
    # Accessions we will process
    $self->{accs}->{$archive_name}->{$epirr_acc}->{$primary_accession}++;
    # Lookup for report 
    $self->{acc2project}->{$primary_accession} = $project_name;
  }
}

sub get_services_accessors {
  my ($self) = @_;

  $self->{container}           = $self->{opts}->{cfg_epirr}->c();
  $self->{database_service}    = $self->{container}->resolve( service => 'database/dbic_schema' ); 
  $self->{conversion_service}  = $self->{container}->resolve( service => 'conversion_service' );

  for my $name (@{$self->{opts}->{archive}}){
      $self->{accessors}->{$name} = $self->{conversion_service}->get_accessor($name);
  }
}


# Add option for other types getters (sample) 
# ID status XML
sub fetch_xml_experiment {
  my ($self, $archive, $accession) = @_;
  
  my $errors    = undef;
  my $accessor  = $self->{accessors}->{$archive};
  
  INFO "Fetching Sample: $accession";
  
  my $row = $accessor->experiment_xml( $accession, $errors );
  croak Dumper ($errors) if(defined $errors);
  croak "Row in the experiment table expected to have 3 coloums" if(scalar @{$row} != 3);
  croak "Given and returned accession differ ($accession vs $row->[0]) " if ($accession ne $row->[0]);
  
  my $experiment = $accessor->extract_metadata_from_experiment_xml( $row, $errors );
  croak Dumper ($errors) if(defined $errors);
  croak "No sample found for $accession"  if (! $experiment->sample_id());
  
  return($row, $experiment);
}

sub fetch_xml_sample {
  my ($self, $experiment, $archive) = @_;

  my $accessor = $self->{accessors}->{$archive};
  my $errors = undef;
  INFO "Fetching Sample: ".$experiment->sample_id();
  my $sample_row = $accessor->lookup_sample( $experiment->sample_id(), $errors );
  croak Dumper ($errors) if(defined $errors);
  croak "Row in the Sample table expected to have 2 coloums" if(scalar @{$sample_row} != 2);
  
  my ( $sample_id, $sample_xml ) = @$sample_row;

  my $sample = $accessor->xml_parser()->parse_sample( $sample_xml, $errors );

  return($sample, $sample_xml);
}

#  errs.sample.1.CKH.ERS.Sep-10-2018-22.22.26.log
sub remove_error_logs {
  my ($self) = @_;
  my @files = glob($self->{opts}->{logs});
  my $t = scalar @files;
  # croak "Found $t logs, 0 or 1 expected" if($t != 0 and $t != 1);
  return 0 if($t == 0);
  # INFO "Found error log from validator: " . $files[0];
  my $unlinked = unlink (@files) or croak "Could not remove error logs: $!";
  return $unlinked;
}



sub write_xml_file {
  my ($self, $accession, $xml) = @_;

  my $file = File::Spec->catfile($self->{opts}->{work_dir}, "$accession.xml");
  
  open my $fh, '>', $file;
    binmode($fh, ":utf8");
    print $fh $xml;
  close $fh;

  return($file);
}

# Redirect output in tmp files
# Check STDOUT for validated: x and failed: y
sub run_py {
  my ($self, $array_args, $file1, $file2) = @_; 
  # DEBUG  ( caller(1) )[3] ."\tLine: ". ( caller(0) )[2];
  INFO "Running Validator";
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
  my ($fh_out, $file_out) = tempfile();
  my ($fh_err, $file_err) = tempfile();
  my $cmd = "python $py_main $args -config:$cfg_json -out:$file1 $file2 >$file_out 2>$file_err";
  $self->run_cmd($cmd);

  # Not the most elegant solution. More than one means at the time of writing that -extract is run
  if(scalar @$array_args == 1){
    my $out = path($file_out)->slurp;
    if( $out =~ /validated: 0/ and $out =~ /failed: 1/ ){
      return "Failed";
    }
    elsif ( $out =~ /validated: 1/ and $out =~ /failed: 0/ ){
      return "Passed";
    }
  }
}


sub run_cmd {
  my ($self, $cmd) = @_;

  die "Nothing passed to execute" if(!$cmd);
  TRACE $cmd;
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
    # printf "child exited with value %d\n", $? >> 8;
  }
}

sub parse_options {
  my ($self) = @_;

  # undef so missing arguments are caught.
  # Add option accessions for filtering. Store as hash
  my $opts = {
    cfg_epirr     => 'EpiRR::Config::Production',
    cfg_ihec_json => "$HOME/src/ihec-ecosystems/version_metadata/config.json",
    work_dir      => $WORKDIR,
    ihec_dir      => $VALIDATOR,
    archive       => ['ENA', 'EGA'],
    project       => '',
    accessions    => [],
    json_dir      => '',
  };
  
  GetOptions($opts, qw/
    cfg_epirr=s
    cfg_ihec_json=s
    work_dir=s
    ihec_dir=s
    archive:s{,}
    project:s{,}
    accessions=s{,}
    json_dir=s

    legacy
    debug
    clean
    help
    verbose
  /) or pod2usage(-msg => 'Misconfigured options given', -verbose => 1, -exitval => 1);
  pod2usage(-verbose => 1, -exitval => 0) if $opts->{help};

  my @required = qw (cfg_epirr cfg_ihec_json work_dir ihec_dir archive);
  die pod2usage() unless all { defined $opts->{$_} } @required;

  Log::Log4perl->easy_init($DEBUG) if $opts->{debug} ;


  #Sanity Checks
  croak('"-work_dir '. $opts->{work_dir} .'" is not a directory') unless ( -d $opts->{work_dir} );
  croak('"-ihec_dir '. $opts->{ihec_dir} .'" is not a directory') unless ( -d $opts->{ihec_dir} );
  croak('"-cfg_ihec_json '. $opts->{cfg_ihec_json} .'" not found') unless ( -e $opts->{cfg_ihec_json} );
  
  eval ('require ' . $opts->{cfg_epirr} ) or croak('-cfg_epirr '. $opts->{cfg_epirr} . 'Cannot load module ' . $@);
  
  $self->{py_main}    = File::Spec->catfile($opts->{ihec_dir}.'__main__.py');
  croak "Could not find __main__.py in ihec_dir [" . $opts->{ihec_dir} ."]" if(!-e $self->{py_main});
  $self->{py_review}  = File::Spec->catfile($opts->{ihec_dir}.'review.py');
  croak "Could not find review.py in ihec_dir [" . $opts->{ihec_dir} ."]" if(!-e $self->{py_review});

  if(defined $opts->{json_dir}){
    say "-json_dir set. Removing -archive, -project, -accessions";
    $opts->{archive} = [];
    $opts->{project} = '';
    $opts->{accessions} = [];
    my $d = $opts->{json_dir};
    croak "-json_dir $d not found" if(!-d $d); 
  }
  # 
  # should be done dynamic. Lack of experience using DBIx
  if(scalar @{$opts->{archive}} == 0){
    $opts->{archive} = [qw (AE DBGAP DDBJ EGA ENA GEO JGA SRA)]; 
  }

  # Could not find a way to directly map from options
  my %tmp = map { $_ => 1 } @{$opts->{accessions}};
  $opts->{accessions} = \%tmp;

  # Used frequently, still should probably be defined somewhere else
  $opts->{logs} = File::Spec->catfile(getcwd, 'errs.[experimentsample]*.log');

  return $self->{opts} = $opts;
}




