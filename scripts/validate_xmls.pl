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

my $report_file_name = "$dir/summary." . time . ".tsv";
open my $r_fh, '>', $report_file_name;
print $r_fh
  join( "\t", qw( File Project Local_name Description Status EpiRR_ID Errors ) )
  . $/;

my $container = $config_module->c();
my $database_service = $container->resolve( service => 'database/dbic_schema' );
my $conversion_service = $container->resolve( service => 'conversion_service' );
my @all_raw_data = $database_service->raw_data->all;

foreach my $raw_data(@all_raw_data){
  if ( $raw_data->archive->name eq 'EGA' || $raw_data->archive->name eq 'ENA' || $raw_data->archive->name eq 'DDBJ' ) {
    if ( $raw_data->dataset_version->is_current ) {
      my $errors = [];
      my @list_of_EGAX = ($raw_data->primary_accession,);

      foreach my $n (@list_of_EGAX) {
	if( $n eq "EGAX00001272789") {
        
	my $accessor = $conversion_service->get_accessor( $raw_data->archive->name );
        	
        print "-------------------------\n";
        print "Looking at experiment: $n\n";

	my $exp_row = $accessor->experiment_xml( $n, $errors );
        my ( $exp_id, $status_id, $experiment_xml ) = @$exp_row; 
        
        open my $exp_xml_fh, '>', "$exp_id.xml";
	print $exp_xml_fh $experiment_xml;
        close $exp_xml_fh;

        my $experiment = $accessor->extract_metadata_from_experiment_xml( $exp_row, $errors ); 
        
        my $sample_row = $accessor->lookup_sample( $experiment->sample_id(), $errors ) if ($experiment->sample_id());
	my ( $sample_id, $sample_xml ) = @$sample_row;

        print "Sample ID from experiment: ".$experiment->sample_id()." and that from the sample database is: $sample_id \n";

	open my $sample_xml_fh, '>', "$sample_id.xml";
	print $sample_xml_fh $sample_xml."\n";
        close $sample_xml_fh;

        my $cmd = "python lib/ihec-ecosystems/version_metadata/__main__.py -sample -config:lib/ihec-ecosystems/version_metadata/config_edited.json -out:./".$sample_id.".versioned.xml ./".$sample_id.".xml";
	system($cmd);
      }}
    }
  }
}

close $r_fh;

