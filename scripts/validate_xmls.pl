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
print $r_fh "EpiRR accession\tProject name\tExperiment/Sample ID\tValidates?\tErrors\n";

my $container = $config_module->c();
my $database_service = $container->resolve( service => 'database/dbic_schema' );
my $conversion_service = $container->resolve( service => 'conversion_service' );
my @all_raw_data = $database_service->raw_data->all;

my $count=0;
foreach my $raw_data(@all_raw_data){
  if ( $raw_data->archive->name eq 'EGA' || $raw_data->archive->name eq 'ENA' || $raw_data->archive->name eq 'DDBJ' ) {
    my $project_name=$raw_data->dataset_version->dataset->project->name;
    my $epirr_accession=$raw_data->dataset_version->dataset->accession;

    if ( $raw_data->dataset_version->is_current ) {
      my $errors = [];
      my @list_of_EGAX = ($raw_data->primary_accession,);

      foreach my $n (@list_of_EGAX) {
	#if( $n eq "EGAX00001147727" || $n eq "EGAX00001272789" || $n eq "EGAX00001272563" || $n eq "EGAX00001169503" ) {
        #if ( $count <= 1000 ) {
	my $accessor = $conversion_service->get_accessor( $raw_data->archive->name );
        	
        print "\n-------------------------\n";
        print "Experiment: $n\n";

	my $exp_row = $accessor->experiment_xml( $n, $errors );
        my ( $exp_id, $status_id, $experiment_xml ) = @$exp_row; 
        
        open my $exp_xml_fh, '>', "$exp_id.xml";
        binmode($exp_xml_fh, ":utf8");
	print $exp_xml_fh $experiment_xml;
        close $exp_xml_fh;

        my $cmd = "python lib/ihec-ecosystems/version_metadata/__main__.py -experiment -config:lib/ihec-ecosystems/version_metadata/config_edited.json -out:./".$exp_id.".versioned.xml ./".$exp_id.".xml";# 2> /dev/null";
	system($cmd);

        my $exp_val_flag="False"; my $exp_val_errors=""; my @exp_val_log_files=glob("errs.experiment*.log");
        if ( scalar @exp_val_log_files == 1) {
          foreach my $exp_val_log_file ( glob("errs.experiment*.log") ) {
            #open my $exp_val_log_file_fh, '<', $exp_val_log_file;
            #while(my $line=<$exp_val_log_file_fh>) {
            #  if ($line =~ m/Failed validating/) {
            #    last;
            #  } else {
            #    chomp($line);
                #$line="not valid under any of the given schemas" if ( $line =~ m/is not valid under any of the given schemas/);
  
             #   $exp_val_errors.="$line; " if ( $line ne "");
             # }
            #}
            #close($exp_val_log_file_fh);

            system("rm $exp_val_log_file");
          }

          system("rm ./".$exp_id.".versioned.xml");
          $cmd = "python lib/ihec-ecosystems/version_metadata/__main__.py -experiment -extract -config:lib/ihec-ecosystems/version_metadata/config_edited.json -out:./".$exp_id.".versioned.xml ./".$exp_id.".xml"; #2> /dev/null";
          system($cmd);

          $cmd = "python lib/ihec-ecosystems/version_metadata/review.py -sample ./".$exp_id.".xml.extracted.json";

          my $review_xml_output = `$cmd`;
          chomp $review_xml_output;

          #$review_xml_output=~ s/[u*\[\]]//g;

          #$exp_val_errors.="Missing ".$review_xml_output;
          $exp_val_errors.=$review_xml_output;
        } elsif ( scalar @exp_val_log_files > 1 ) {
          print "Found too many experiment log files: ".scalar @exp_val_log_files."\n";
          exit;
        } else { $exp_val_flag="True"; }
      
        print $r_fh "$epirr_accession\t$project_name\t$exp_id\t$exp_val_flag\t$exp_val_errors\n";
        system("rm -f ./".$exp_id.".versioned.xml ./".$exp_id.".xml.extracted.json ./".$exp_id.".xml");
 
        my $experiment = $accessor->extract_metadata_from_experiment_xml( $exp_row, $errors ); 
        
        my $sample_row = $accessor->lookup_sample( $experiment->sample_id(), $errors ) if ($experiment->sample_id());
	my ( $sample_id, $sample_xml ) = @$sample_row;

        my $sample = $accessor->xml_parser()->parse_sample( $sample_xml, $errors );        

        print "\n-------------------------\n";
        print "Sample: $sample_id\n";

	open my $sample_xml_fh, '>', "$sample_id.xml";
	binmode($sample_xml_fh, ":utf8");
        print $sample_xml_fh $sample_xml."\n";
        close $sample_xml_fh;

        $cmd = "python lib/ihec-ecosystems/version_metadata/__main__.py -sample -config:lib/ihec-ecosystems/version_metadata/config_edited.json -out:./".$sample_id.".versioned.xml ./".$sample_id.".xml"; #2> /dev/null";
	system($cmd);

        my $sample_val_flag="False"; my $sample_val_errors=""; my @sample_val_log_files=glob("errs.sample*.log");

	$sample_val_errors.="Missing 'MOLECULE'; " if ( ! ( $sample->get_meta_data('molecule') || $experiment->get_meta_data('molecule')));
        if ( scalar @sample_val_log_files == 1) {

          foreach my $sample_val_log_file ( @sample_val_log_files ) {
            system("rm $sample_val_log_file");
          }  
            #print "\n-------------------------------------\n";
            #print "Reading from file: $sample_val_log_file\n";
            #print "\n-------------------------------------\n";

          #  open my $sample_val_log_file_fh, '<', $sample_val_log_file;
          #  while(my $line=<$sample_val_log_file_fh>) {
          #    if ($line =~ m/^Failed validating/) {
          #      last;
          #    } else {
          #      chomp($line);
                #print "\n$line\n";
                #$line="not valid under any of the given schemas" if ( $line =~ m/is not valid under any of the given schemas/);
          #      $sample_val_errors.="$line; " if ( $line ne "" );
          #    }
          #  }
          #  close($sample_val_log_file_fh);

          system("rm ./".$sample_id.".versioned.xml");
          $cmd = "python lib/ihec-ecosystems/version_metadata/__main__.py -sample -extract -config:lib/ihec-ecosystems/version_metadata/config_edited.json -out:./".$sample_id.".versioned.xml ./".$sample_id.".xml"; #2> /dev/null";
          system($cmd);

          $cmd = "python lib/ihec-ecosystems/version_metadata/review.py -sample ./".$sample_id.".xml.extracted.json";

          my $review_xml_output = `$cmd`;
          chomp $review_xml_output;

          #$review_xml_output=~ s/[u*\[\]]//g;

          $sample_val_errors.=$review_xml_output;
          #$sample_val_errors.="Missing ".$review_xml_output;
        } elsif ( scalar @sample_val_log_files > 1 ) { 
          print "Found too many log files: ".scalar @sample_val_log_files."\n";
          exit;
        } elsif ( $sample_val_errors eq "" ) { $sample_val_flag="True"; }

        print $r_fh "$epirr_accession\t$project_name\t$sample_id\t$sample_val_flag\t$sample_val_errors\n";
        system("rm -f ./".$sample_id.".versioned.xml ./".$sample_id.".xml.extracted.json ./".$sample_id.".xml");
      
        #$count+=1;
      }#}
    }
  }
}

close $r_fh;

