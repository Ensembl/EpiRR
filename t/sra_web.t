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
    my $actual = $w->lookup_experiment('SRX007379');

    my $expected = EpiRR::Model::RawData->new(
        primary_id      => 'SRX007379',
        experiment_type => 'Histone H3K27me3',
        secondary_id    => 'SRS004524',
    );

    is_deeply( $actual, $expected, "Parse Experiment" );
}

{
    my $actual = $w->lookup_sample('SRS004524');

    my $expected = EpiRR::Model::Sample->new(
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

    is_deeply( $actual, $expected, 'Parsed Sample' )
}

done_testing();

