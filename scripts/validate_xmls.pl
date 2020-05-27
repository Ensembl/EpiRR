#!/usr/bin/env perl

use warnings;
use strict;
use feature qw(say);

use Getopt::Long;
use Readonly;
use Log::Log4perl qw(:easy);
use DBI;
use XML::LibXML;

use Cwd;
use File::Path qw(make_path rmtree);
use File::Spec;  
use File::chdir;
use File::Slurper qw(read_text);

use Path::Tiny;

use JSON::MaybeXS qw(encode_json decode_json);

use Data::Printer;
use Data::Dump qw(pp);

use Data::Dumper;
$Data::Dumper::Indent   = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Deepcopy = 1;
$Data::Dumper::Terse    = 1;

# Default Log level
Log::Log4perl->easy_init($INFO);

# location of https://github.com/IHEC/ihec-ecosystems
use constant IHEC_DIR         => $ENV{IHEC_DIR};
# log files and some temporary files are written here
use constant WORK_DIR         => $ENV{VALIDATOR_WORK_DIR};
# tmp dir location
use constant TMP_DIR          => $ENV{VALIDATOR_TMP_DIR}; 
# used for downloading Experiment & Sample XMLs
use constant DL_DIR           => $ENV{VALIDATOR_DL_DIR}; 
# EpiRR config, should in general point to Production. Provides access to ERAPRO DB
use constant CFG_EPIRR        => 'EpiRR::Config::Production';

# Validator config.json, found in ihec-ecosystems/version_metadata/config.json
use constant VALIDATOR_CFG    => $ENV{VALIDATOR_CFG};

# Files used when running the validator
use constant EXPERIMENT_XML   => File::Spec->catfile(TMP_DIR, 'experiment.xml');
use constant SAMPLE_XML       => File::Spec->catfile(TMP_DIR, 'sample.xml');
use constant VALIDATOR_JSON   => File::Spec->catfile(TMP_DIR, 'log.json');
use constant VALIDATOR_STDOUT => File::Spec->catfile(TMP_DIR, 'stdout.out');
use constant VALIDATOR_STDERR => File::Spec->catfile(TMP_DIR, 'stderr.err');
use constant VALIDATOR_OUT    => File::Spec->catfile(TMP_DIR, 'versioned.xml');


# Archives which can be accessed directly through ERAPRO DB
Readonly our $VALID_ARCHIVES => [
  'ddbj', 
  'ega', 
  'ena'
  ]; 

# Projects currently in EpiRR, copied from projects table. Unlikely to change often
Readonly our $VALID_PROJECTS => [
  'amed-crest',
  'blueprint',
  'ceehrc',
  'deep',
  'encode',
  'epp',
  'gis',
  'hipsci',
  'korea epigenome project (knih)',
  'nih roadmap epigenomics',
  'epihk',
];

# # Statistics
# our $statistic = {};

main();

sub main {

  my $options = get_options();
  set_log_level($options);
  create_directories($options);
  check_options_and_environment_variables($options);
  iterate($options);

}

=head2 create_directories

  Description: 

=cut

sub create_directories {
  my ($options) = @_;

  remove_directory(WORK_DIR) if($options->{clean});
  create_directory(WORK_DIR);
  remove_directory(TMP_DIR);
  create_directory(TMP_DIR);
  create_directory(DL_DIR) if($options->{keep});
}

=head2 create_directory

  Description: 
  Returntype: 

=cut

# Create working and tmp directory. make_path == mkdir -p
sub create_directory {
  my ($dir) = @_;

  eval { make_path($dir) };
  if ($@) {
    die "Couldn't create $dir Error: $@";
  }
  DEBUG "Created directory: $dir";
}


=head2 remove_directory

  Description: 
  Returntype: 

=cut

sub remove_directory {
  my ($dir) = @_;
  
  return unless (-d $dir);

  eval { rmtree($dir) };
  if ($@) {
    die "Couldn't remove $dir Error: $@";
  }
  DEBUG "Removed directory: $dir";
}

=head2 iterate

  Description: 
  Returntype: 

=cut

sub iterate {
  my ($options) = @_;

  my $oracle_queries = prepare_oracle_queries();
  my $records        = fetch_epirr_accessions($options);

PROJECT:
  foreach my $project ( sort keys $records ) {
    my $report    = {};
    my $statistic = {};
    foreach my $ihec ( sort keys $records->{$project} ) {
      INFO "IHEC: $ihec";
      $statistic->{$project}->{ihec}++;
      my @experiment_accessions = split(',', $records->{$project}->{$ihec});
      foreach my $e_acc (@experiment_accessions) {
        INFO "Processing: $project\t$ihec\t$e_acc";
        
        remove_directory(TMP_DIR);
        create_directory(TMP_DIR);
        
        my $sample_acc = 
          create_xml_records($options, $e_acc, $oracle_queries);
        
        $report->{$project}->{$ihec}->{$e_acc} = {};
        $report->{$project}->{$ihec}->{$sample_acc} = {};
        

        validate('experiment');
        parse_validator_json($report->{$project}->{$ihec}->{$e_acc});
        validate_molecule($report->{$project}->{$ihec}->{$e_acc});
        create_statistics   ($statistic, $report->{$project}->{$ihec}->{$e_acc}, $project);
        
        validate('sample');
        parse_validator_json($report->{$project}->{$ihec}->{$sample_acc});
        create_statistics   ($statistic, $report->{$project}->{$ihec}->{$sample_acc}, $project);
        # last PROJECT;
      }
    }
    write_reports($statistic, $report, $project);
  }
}

=head2 write_reports

  Description: 
  Returntype: 

=cut

sub write_reports {
  my ($statistic, $report, $project) = @_;
  my $date=`date +%Y%m%d%H%M`;
  chomp($date);

  my $errors = File::Spec->catfile(WORK_DIR,$project.".$date.errors.txt"); 
  my $stats  = File::Spec->catfile(WORK_DIR,$project.".$date.statistics.txt"); 

  write_file($errors, Dumper $report);
  write_file($stats, Dumper $statistic);

}

=head2 validate_molecule

  Description:  In the early days it was possible for the MOLECULE to be defined in either
                Exeperiment or Sample. The validator can't check both, hence it is performed 
                here. 

=cut

sub validate_molecule {
  my ($report) = @_;

  my $exp_xml    = path(EXPERIMENT_XML)->slurp;
  my $sample_xml = path(SAMPLE_XML)->slurp;

  if ( $sample_xml =~ m!<TAG>MOLECULE</TAG>!o and $exp_xml !~ m!<TAG>MOLECULE</TAG>!o ) {
    push @{$report->{'1.0'}->{errors}}, "MOLECULE defined in Sample, not Experiment";
    $report->{'1.0'}->{status} = 0;
  }
  elsif ( $exp_xml !~ m!<TAG>MOLECULE</TAG>!o and $sample_xml !~ m!<TAG>MOLECULE</TAG>!o ) {
    push @{$report->{'1.0'}->{errors}}, "MOLECULE not defined";
    $report->{'1.0'}->{status} = 0;
  }

}

=head2 create_statistics

  Description:  Update statistics hash, adding validated or failed experiments. 
                Remove Validated records from report for better readability

=cut



sub create_statistics {
  my ($statistic, $report, $project) = @_;
  
  foreach my $version (sort keys %$report){
    my $status = $report->{$version}->{status};
    if ($status == 0)  {
      $statistic->{$project}->{$version}->{Failed}++;
      delete $report->{$version}->{status};
    }
    if ($status == 1)  {
      $statistic->{$project}->{$version}->{Validated}++;
      delete $report->{$version};
    }
  }
}

=head2 create_xml_records

  Description:  Writes XML files used in current validator run.
                If -keep, also writes the XML file to the designated 
                download directory
=cut

sub create_xml_records {
  my ($options, $e_acc, $oracle_queries) = @_; 

  my $xmls = fetch_xmls($e_acc, $oracle_queries);
  
  write_file(EXPERIMENT_XML, $xmls->{experiment_xml});
  write_file(SAMPLE_XML,     $xmls->{sample_xml});
  
  if($options->{keep}){
    my $file = File::Spec->catfile(DL_DIR, $xmls->{experiment_acc}.'.xml');
    DEBUG "Experiment filename: $file";
    write_file($file, $xmls->{experiment_xml});
    
    $file = File::Spec->catfile(DL_DIR, $xmls->{sample_acc}.'.xml');
    DEBUG "Sampe filename: $file";
    write_file($file, $xmls->{sample_xml});
  }
  return $xmls->{sample_acc};
}

=head2 write_file

  Description:  Opens a file at the given path and prints the content.
                Uses binmode UTF8 to print special characters correctly.

=cut

sub write_file {
  my ($file, $content) = @_;

  open my $fh, '>', $file or die "Could not open file: $file. Error $!";
    binmode($fh, ":utf8");
    print $fh $content;
  close $fh;
  DEBUG "$file finished writing";
}

=head2 parse_validator_json

  Description: Parse the JSON output produced by the validator.
  ToDo: Improve variables names

=cut

sub parse_validator_json {
  my ($report) = @_;

  my $content = read_text(VALIDATOR_JSON);
  DEBUG "Validator JSON:\n$content";
  my $j = '';

  eval { $j = decode_json($content) };
  if ($@){
    die "invalid json. File:".VALIDATOR_JSON."\n error: $@:";
  }

  foreach my $file_name (keys %{$j} ){
    foreach my $k (@{$j->{$file_name}}){
      foreach my $acc (keys %{$k}){
        my $version = $k->{$acc}->{version};
        $report->{$version}->{errors} = $k->{$acc}->{errors};                                                                                                                                              
        $report->{$version}->{status} = convert_status($k->{$acc}->{ok});  
      }   
    }   
  }
  DEBUG "Parsed Validator results" . Dumper($report); 
}

=head2 convert_status

  Description:  Status is converted to 'JSON::PP::Boolean' when decoding.
                Replace with integer.

=cut

sub convert_status {
  my ($status) = @_;

  DEBUG "status: $status";
  return 1 if($status);
  return 0 if(!$status);
}

=head2 validate

  Description:  Run the validator. 
                Validator needs to run in IHEC directory

=cut

sub validate {
  my ($type) = @_;

  die "Only experiment or sample accepted " unless ($type =~ /^(?:experiment|sample)$/);

  local $CWD = IHEC_DIR;
  DEBUG "Current directory: " . getcwd();

  my $cmd = create_command($type);
  DEBUG "Executing:\n" . $cmd;

  system($cmd)  == 0 or die "FAILED to execute\n$cmd\nError: $?";
}

=head2 create_command

  Description:  Command to run the validator is slightly different depening on
                if it a Sample or Experiment is tested.

=cut

sub create_command {
  my ($type) = @_;

  
  my @cmd;
  push(@cmd, 'python');
  push(@cmd, '-m');
  push(@cmd, 'version_metadata');
  push(@cmd, '-config:'.VALIDATOR_CFG);
  push(@cmd, '-overwrite-outfile');
  push(@cmd, '-out:'.VALIDATOR_OUT);
  push(@cmd, '-jsonlog:'.VALIDATOR_JSON);
  
  if ($type eq 'experiment'){
    push(@cmd, '-experiment');
    push(@cmd, EXPERIMENT_XML);
  }
  else{
    push(@cmd, '-sample');
    push(@cmd, SAMPLE_XML);
  }

  push(@cmd, '>'.VALIDATOR_STDOUT);
  push(@cmd, '2>'.VALIDATOR_STDERR);

  # system does not allow redirection of STDOUT and STDERR when passing an array
  return (join(" ", @cmd));

}

=head2 fetch_xmls

  Description: Fetch Experiment XML using accession stored in EpiRR. 
               Try basic test if XML is valid. 
  Returntype: hash ref

=cut

sub fetch_xmls {
  my ($e_acc, $oracle_queries) = @_;

  #warn "Data fetching terminated early by error: $DBI::errstr\n"  if $DBI::err;
  my $archive = assign_accession_archive($e_acc);
  
  DEBUG "Archive for experiment accession: $archive";
  $oracle_queries->{$archive}->{exp}->execute($e_acc);
  my ($e_xml) = $oracle_queries->{$archive}->{exp}->fetchrow_array();
  DEBUG "Experiment XML:\n$e_xml";
  test_xml($e_xml);
 
  $oracle_queries->{$archive}->{sample}->execute($e_acc);
  my ($sample_acc, $sample_xml) = $oracle_queries->{$archive}->{sample}->fetchrow_array();
  DEBUG "Sample_acc: $sample_acc\nSample XML:\n".Dumper ($sample_xml);
  test_xml($sample_xml);
  
  return ({
      'experiment_acc' => $e_acc, 
      'experiment_xml' => $e_xml, 
      'sample_acc' => $sample_acc, 
      'sample_xml' => $sample_xml, 
    } );

}

=head2 assign_accession_archive

  Description: Links Experiment accession to archive.
               Necessary to pick the correct SQL
  Error: Throws if accession does not match

=cut

sub assign_accession_archive {
  my ($acc) = @_;

  return 'ega' if($acc =~ /^EGAX\d*$/);
  return 'ena' if($acc =~ /^(?:DRX|ERX)\d*$/);
  die "Accession '$acc' not matching ega (^EGAX\d*$) or ENA (^DRX|ERX\d*$)";
}

=head2 test_xml

  Description: Tries to load XML, which performs basic validation tests.
  Returntype: None
  Error: Throws if XML is not valid 
  ToDo: Could be used to perform XSD test

=cut

sub test_xml {
  my ($xml) = @_;

  # Loader complains if XML is malformed or string is empty
  # If neecessary, validate function can test against XSD
  my $dom = eval {XML::LibXML->load_xml(string => \$xml);};
  if ($@){
    die "Malformed XML. Error: $@";
  }
}



=head2 get_options

  Description: Process command line option
  Returntype: hash ref

=cut


sub get_options {
  my $options = read_command_line();
  
  return $options;
}

=head2 read_command_line

  Description: Option reading. Parses the command line
  Returntype: hash ref

=cut

sub read_command_line {
  DEBUG "read_command_line";

  #splitting command line options, predeclaration required
  my $options = {
    archive       => [],
    project       => [],
    accessions    => [],
  };

  # split command line arguments into comma separated list
  my $splitter = sub {
    my ($name, $val) = @_;
    push @{$options->{$name}}, split q{,}, $val;
  };
  
  GetOptions($options,
    'archive=s@'        => $splitter,
    'project=s@'        => $splitter,
    'ihec_accession=s@' => $splitter,
    'legacy', # MOLECULE can be in Sample or Experiment
    'debug',
    'clean',
    'keep',
    'help',
    'verbose',
  ) or pod2usage(-msg => 'Misconfigured options given', -verbose => 1, -exitval => 1);
  pod2usage(-verbose => 1, -exitval => 0) if $options->{help};

  INFO "Command line arguments: " . Dumper $options;
  # print Dumper $options;
  return $options;
}

=head2 check_options_and_environment_variables

  Description: Validates arguments, sets defaults
  Returntype: None

=cut

sub check_options_and_environment_variables {
  my ($options) = @_;

  check_environment_variables();
  check_projects_options($options);
  check_archive_options($options);
  check_ihec_accession_options($options);
}




=head2 set_log_level

  Description: Set Log level.

=cut

sub set_log_level {
  my ($options) = @_;

  Log::Log4perl->easy_init($DEBUG) if $options->{debug};
  DEBUG "Log Level DEBUG";
}


=head2 check_environment_variables

  Description: Checks mandatory variables that need to be that in the shell environment

=cut

sub check_environment_variables {
  DEBUG "check_environment_variables";

  die "Validator Config not found or set in environment"             unless (-e $ENV{VALIDATOR_CFG}      );
  die "Working directory not found or set in environment"            unless (   $ENV{VALIDATOR_WORK_DIR} );
  die "tmp directory not found or set in environment"                unless (   $ENV{VALIDATOR_TMP_DIR}  );
  die "Download directory not found or set in environment"           unless (   $ENV{VALIDATOR_DL_DIR}   );
  die "'ihec-ecosystems' directory not found or set in environment"  unless (-d $ENV{IHEC_DIR} );

  die "Oracle DB DSN not found or set in environment"   unless ($ENV{ERA_DSN});
  die "Oracle DB USER not found or set in environment"  unless ($ENV{ERA_USER});
  die "Oracle DB PW not found or set in environment"    unless ($ENV{ERA_PASS});

  die "EpiRR DB DSN not found or set in environment"   unless ($ENV{EPIRR_DSN});
  die "EpiRR DB USER not found or set in environment"  unless ($ENV{EPIRR_USER});
  die "EpiRR DB PW not found or set in environment"    unless ($ENV{EPIRR_PASS})
}

=head2 check_projects_options

  Description: Checks if specific projects were selected, test if valid if so

=cut

sub check_projects_options {
  my ($options) = @_;

  DEBUG "Projects from command line: " . Dumper $options->{project};

  if(defined $options->{project} and scalar @{$options->{project}} > 0  ){
    $_ = lc for @{$options->{project}};
    my %valid = map { $_ => 1 } @$VALID_PROJECTS; 
    foreach my $project (@{$options->{project}}) {
      if( !exists($valid{$project}) ){
        die  ">$project< is not a valid project. Valid projects are: " . Dumper $VALID_PROJECTS;
      }
    }
  }
  else {
    $options->{project} = undef;
  }
}

=head2 check_archive_options

  Description:  Checks if specific archives were selected
                As we can only process

=cut

sub check_archive_options {
  my ($options) = @_;

  DEBUG "Archives from command line: " . Dumper $options->{archive};

  if(defined $options->{archive} and scalar @{$options->{archive}} > 0  ){
    $_ = lc for @{$options->{archive}};
    my %valid = map { $_ => 1 } @$VALID_ARCHIVES; 
    foreach my $archive (@{$options->{archive}}) {
      if(  !exists($valid{$archive}) ){
         die ">$archive< is not a valid archive. Valid archives are: " . Dumper $VALID_ARCHIVES;
      }
    }
  }
  else {
    # Makes a later check shorter
    $options->{archive} = $VALID_ARCHIVES;
  }
}

=head2 check_ihec_accession_options

  Description: Validates IHEC accesions, if selected
  Returntype: None

=cut

sub check_ihec_accession_options {
  my ($options) = @_;

  if(defined $options->{ihec_accession} and scalar @{$options->{ihec_accession}} > 0  ){
    foreach my $ihec (@{$options->{ihec_accession}}) {
      die "Invalid IHEC accession '$ihec'" unless ($ihec =~ /^IHECRE\d{8}$/);
    }
  }
  else {
    $options->{ihec_accession} = undef;
  }
}

=head2 fetch_epirr_accessions

  Description: Connect to EpiRR and fetch relevant (filtered by project and archive) accessions
  Returntype: None

=cut

sub fetch_epirr_accessions {
  my ($options) = @_;

  my $dsn  = $ENV{EPIRR_DSN};
  my $user = $ENV{EPIRR_USER};
  my $pass = $ENV{EPIRR_PASS};
  DEBUG "DSN: $dsn\tUser: $user\tPW: $pass";
  
  my $dbh = DBI->connect( $dsn, $user, $pass, 
    { 'RaiseError' => 1, 'PrintError' => 0 } ) or die "Could not connect: $!";
  
  # GROUP_CONCAT has 1024 characters limitation
  $dbh->do(q{SET SESSION group_concat_max_len = 1000000});
  
  INFO "Connected to DSN: $dsn as $user"; 
  my $archive = "'".join("','", @{$options->{archive}})."'";
  my $sql = "
    SELECT  
      project.name                    as project, 
      accession                       as ihec,  
      GROUP_CONCAT(primary_accession) as experiment
    FROM 
      dataset 
    JOIN project          USING (project_id) 
    JOIN dataset_version  USING (dataset_id) 
    JOIN raw_data         USING (dataset_version_id) 
    JOIN archive          USING (archive_id) 
    WHERE 
      is_current = 1
    AND archive.name IN ($archive)
  ";
  if(my $c = create_epirr_constraints($options)){
    $sql .= $c;     
  }
  $sql .= "
    GROUP BY
      project.name, 
      accession
  ";
  DEBUG "SQL: Fetch accessions from EpiRR:\n$sql";

  my $sth = $dbh->prepare($sql) or die "Unable to prepare $sql" . $dbh->errstr;
  $sth->execute() or die "Unable to execute '$sql'.  " . $sql->errstr;

  my $records_to_validate;
  
  # declaring in while loop results in a scope issue, 1 undef record will be retrieved.
  my $r = {};
  while ( $r  = $sth->fetchrow_hashref ){
    my $project   = lc($r->{project});
    my $ihec      = $r->{ihec};
    my $exp_accs  = $r->{experiment};
    $records_to_validate->{$project}->{$ihec} = $exp_accs ;  
  }
  $sth->finish;
  $dbh->disconnect
    or warn "Disconnection from EpiRR database failed: $DBI::errstr\n";

  DEBUG "Records to validate: " . Dumper $records_to_validate;
  return $records_to_validate;
}

=head2 create_epirr_constraints

  Description: Check if any constraints were selected, create string
  Returntype: string containing SQL constraints

=cut


sub create_epirr_constraints {
  my ($options) = @_;

  my $constraints = undef;

  if( defined $options->{project} ){
    my $project = "'".join("','", @{$options->{project}})."'";
    $constraints .= "  AND project.name IN ($project)";
  }

  if( defined $options->{ihec_accession} ){
    my $ihec = "'".join("','", @{$options->{ihec_accession}})."'";
    $constraints .= "  AND dataset.accession IN ($ihec)";
  }

  return $constraints;
}


sub prepare_oracle_queries {
  my $oracle_queries = {};

  my $dsn  = $ENV{ERA_DSN};
  my $user = $ENV{ERA_USER};
  my $pass = $ENV{ERA_PASS};

  my $dbh = DBI->connect( $dsn, $user, $pass, 
    { 'RaiseError' => 1, 'PrintError' => 0 } ) or die "Could not connect: $!";
  INFO "Oracle: Connected to DSN: $dsn";
  
  #default is 80, far to short for the XML records
  $dbh->{LongReadLen} = 66600;

  # Used for disconnect later
  $oracle_queries->{dbh_erapro} = $dbh;

  my $sth;
  
  $sth = $dbh->prepare(' 
    SELECT xmltype.getclobval(experiment_xml) 
    FROM experiment 
    WHERE experiment_id = ? 
    AND ega_id IS NULL
  ');
  $oracle_queries->{ena}->{exp} = $sth;

  $sth = $dbh->prepare('
    SELECT sample_id, xmltype.getclobval(sample_xml) as sample_xml 
    FROM sample 
    JOIN experiment_sample USING (sample_id) 
    WHERE experiment_id = ?
  ');
  $oracle_queries->{ena}->{sample} = $sth;

  $sth = $dbh->prepare('
    SELECT xmltype.getclobval(experiment_xml) 
    FROM experiment WHERE ? 
    IN (experiment_id, ega_id) 
    AND ega_id IS NOT NULL
  ');
  $oracle_queries->{ega}->{exp} = $sth;

  $sth = $dbh->prepare('
    SELECT sample.sample_id, xmltype.getclobval(sample_xml) as sample_xml
    FROM sample 
    JOIN experiment_sample ON sample.sample_id         = experiment_sample.sample_id 
    JOIN experiment        ON experiment.experiment_id = experiment_sample.experiment_id 
    WHERE ? IN (experiment.experiment_id, experiment.EGA_ID) 
    AND experiment.EGA_ID IS NOT NULL
  ');
  $oracle_queries->{ega}->{sample} = $sth;

  return $oracle_queries;
}
