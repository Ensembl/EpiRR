#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use File::Basename;

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
            MOLECULE               => 'genomic DNA',
            DISEASE                => 'none',
            BIOMATERIAL_PROVIDER   => 'Cellular Dynamics',
            BIOMATERIAL_TYPE       => 'Cell Line',
            LINE                   => 'H1',
            LINEAGE                => 'undifferentiated',
            DIFFERENTIATION_STAGE  => 'stage_zero',
            DIFFERENTIATION_METHOD => 'none',
            PASSAGE                => '42',
            MEDIUM                 => 'TESR',
            SEX                    => 'Unknown',
            'ENA-SPOT-COUNT'       => '23922417',
            'ENA-BASE-COUNT'       => '1537097042',
            'SPECIES'              => 'Homo sapiens',
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

