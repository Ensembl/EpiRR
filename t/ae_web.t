#!/usr/bin/env perl
# Copyright 2013 European Molecular Biology Laboratory - European Bioinformatics Institute
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
use strict;
use warnings;

use Test::More;
use File::Basename;

use EpiRR::Model::RawData;
use EpiRR::Model::Sample;
use EpiRR::Service::ArrayExpress;

my $ae = EpiRR::Service::ArrayExpress->new();

{
    ok( $ae->handles_archive('AE'),              'Handles archive' );
    ok( !$ae->handles_archive("Dino's Barbers"), 'Does not handle archive' );
}

{
    my $errors = [];
    my $input  = EpiRR::Model::RawData->new(
        archive      => 'AE',
        primary_id   => 'E-GEOD-35522',
        secondary_id => 'GSM870141 1'
    );
    my ( $output_experiment, $output_sample ) =
      $ae->lookup_raw_data( $input, $errors );

    my $expected_sample = EpiRR::Model::Sample->new(
        sample_id => 'SAMEA1438605',
        meta_data => {
            'Organism'          => 'Homo sapiens',
            'age'               => '50 years old',
            'anatomical region' => 'caput',
            'organism part'     => 'epididymis',
            'Sample Description' =>
              'RS_norm-queue-50ans_(miRNA-1_0_2Xgain).CEL',
            'Sample Name' => 'source GSM870141 1',
            'Sample_source_name' =>
              'caput of epididymides from 50 years old man',
            'Sample_title'     => 'caput of epididymides from 50 years old man',
        },
    );

    my $expected_experiment = EpiRR::Model::RawData->new(
        archive         => 'AE',
        primary_id      => 'E-GEOD-35522',
        experiment_type => 'transcription profiling by array',
        archive_url =>
'http://www.ebi.ac.uk/arrayexpress/experiments/E-GEOD-35522/samples/GSM870141%201',
    );

    is_deeply( $output_experiment, $expected_experiment,
        "Found experiment information" );
    is_deeply( $output_sample, $expected_sample, "Found sample information" );
    is_deeply( $errors, [], 'No errors' );
}

done_testing();
