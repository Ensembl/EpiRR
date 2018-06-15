#!/usr/bin/env perl
# Copyright 2014 European Molecular Biology Laboratory - European Bioinformatics Institute
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
use warnings;
use strict;

use EpiRR::Schema;
use Getopt::Long;
use Carp;
use File::Find;
use File::Spec;
use File::Basename;
use autodie;
use feature qw(say);
use Data::Dumper;
use URI::Encode qw(uri_encode);
use LWP;
#has '+base_url'        => ( default => 'https://www.ebi.ac.uk/ega/datasets/' );  
#has '+valid_status_id' => ( default => 2 );

$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Deepcopy = 1;


my $config_module = 'EpiRR::Config';
my $dir;
my $outfile;
my $quiet = 0;

GetOptions(
  "config=s" => \$config_module,
  "dir=s"    => \$dir,
  'quiet!'   => \$quiet,
) or croak("Error with options: $!");

croak("Missing option: -dir") unless ($dir);
croak("-dir $dir is not a directory") unless ( -d $dir );

eval("require $config_module")
  or croak "cannot load module $config_module $@";

my $container = $config_module->c();
my $accession_service = $container->resolve( service => 'accession_service' );

my $report_file_name = "$dir/summary." . time . ".tsv";
open my $r_fh, '>', $report_file_name;
print $r_fh
  join( "\t", qw( File Project Local_name Description Status EpiRR_ID Errors ) )
  . $/;

my $errors = [];
my $database_service = $container->resolve( service => 'database/dbic_schema' );
my $conversion_service = $container->resolve( service => 'conversion_service' );
my $acs = {};
$acs->{EGA} = $conversion_service->get_accessor('EGA');
$acs->{ENA} = $conversion_service->get_accessor('ENA');
$acs->{DDBJ} = $conversion_service->get_accessor('DDBJ');

my @all_raw_data = $database_service->raw_data->all;

foreach my $raw_data(@all_raw_data){
  my $archive_name = $raw_data->archive->name;
  next unless(exists  $acs->{$archive_name});
  next unless($raw_data->dataset_version->is_current);

  my $ac = $acs->{$archive_name};
  foreach my $n ($raw_data->primary_accession) {
    my $experiment = $ac->experiment_xml($n , $errors);
    say $archive_name;die;
#    my ( $exp_id, $status_id, $experiment_xml ) = @$row;
    say Dumper($experiment); die;
    if( $n eq "EGAX00001272789") {


#	my $row = $self->experiment_xml( $n, $errors );
#	my ( $exp_id, $status_id, $experiment_xml ) = @$row;
#        
#	open my $exp_xml_fh, '>', "$exp_id.xml";
#	print $exp_xml_fh $experiment_xml."\n";
#        close $exp_xml_fh;
#
#        my $sample_row = $self->lookup_sample( $experiment->sample_id(), $errors ) if ($experiment->sample_id());
#	my ( $sample_id, $sample_xml ) = @$row;
#
#	open my $sample_xml_fh, '>', "$sample_id.xml";
#	print $sample_xml_fh $sample_xml."\n";
#        close $sample_xml_fh;
#
#        my $cmd = "pipenv run main.py -sample -out:./".$sample_id.".versioned.xml ./".$sample_id.".xml";
#	system$cmd);
    }
  }
}

close $r_fh;

