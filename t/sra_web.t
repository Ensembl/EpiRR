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

use EpiRR::Model::RawData;
use EpiRR::Model::Sample;
use EpiRR::Service::ENAWeb;

my $w = EpiRR::Service::ENAWeb->new();

{
    ok( $w->handles_archive('ENA'),             'Handles archive' );
    ok( !$w->handles_archive("Dino's Barbers"), 'Does not handle archive' );
}

{
    my $input =
      EpiRR::Model::RawData->new( archive => 'ENA', primary_id => 'SRX007379' );
    my ( $output_experiment, $output_sample ) = $w->lookup_raw_data($input);

    my $expected_sample = EpiRR::Model::Sample->new(
        sample_id => 'SRS004524',
        meta_data => {
            molecule               => 'genomic DNA',
            disease                => 'none',
            biomaterial_provider   => 'Cellular Dynamics',
            biomaterial_type       => 'Cell Line',
            line                   => 'H1',
            lineage                => 'undifferentiated',
            differentiation_stage  => 'stage_zero',
            differentiation_method => 'none',
            passage                => '42',
            medium                 => 'TESR',
            sex                    => 'Unknown',
            'ena-spot-count'       => '23922417',
            'ena-base-count'       => '1537097042',
            'species'              => 'Homo sapiens',
        },
    );
    my $expected_experiment = EpiRR::Model::RawData->new(
        archive         => 'ENA',
        primary_id      => 'SRX007379',
        experiment_type => 'Histone H3K27me3',
        archive_url     => 'http://www.ebi.ac.uk/ena/data/view/SRX007379',
    );

    is_deeply( $output_experiment, $expected_experiment,
        "Found experiment information" );
    is_deeply( $output_sample, $expected_sample, "Found sample information" );
}

done_testing();

