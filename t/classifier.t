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

use EpiRR::Service::IhecDatasetClassifier;
use EpiRR::Model::RawData;
use EpiRR::Model::Sample;
use EpiRR::Model::Dataset;
use Test::More;

my $ds = EpiRR::Service::IhecDatasetClassifier->new();

{
    my $input_ds = EpiRR::Model::Dataset->new(
        raw_data => [
            EpiRR::Model::RawData->new(
                experiment_type => 'Anything',
                primary_id      => 'rd1',
                data_type       => 'dt1',
            )
        ]
    );
    my $input_s = [
        EpiRR::Model::Sample->new(
            sample_id => 's1',
            meta_data => { donor_id => 'd1' }
        )
    ];
    my $errors = [];

    my $expected = [ 'Incomplete', 'Single donor' ];
    my @actual = $ds->determine_classification( $input_ds, $input_s, $errors );

    is_deeply( \@actual, $expected, "Simple case" );
    is_deeply( $errors, [], "No errors" );
}

{
    my $input_ds = EpiRR::Model::Dataset->new();
    for my $et (
        [ 'Bisulfite-Seq', 'DNA Methylation' ],
        [ 'ChIP-Seq',      'ChIP-Seq Input' ],
        [ 'ChIP-Seq',      'Histone H3K4me1' ],
        [ 'ChIP-Seq',      'Histone H3K4me3' ],
        [ 'ChIP-Seq',      'Histone H3K9me3' ],
        [ 'ChIP-Seq',      'Histone H3K9ac' ],
        [ 'ChIP-Seq',      'Histone H3K27me3' ],
        [ 'ChIP-Seq',      'Histone H3K36me3' ],
        [ 'RNA-Seq',       'mRNA-seq' ],
      )
    {
        $input_ds->add_raw_data(
            EpiRR::Model::RawData->new(
                data_type       => $et->[0],
                experiment_type => $et->[1],
                primary_id      => 'rd1',
            )
        );
    }
    my $errors = [];
    my $status = $ds->experimental_completeness( $input_ds, $errors );

    is( $status, 'Complete', "Complete" );
    is_deeply( $errors, [], "No errors" );
}

{
    my $input_ds = EpiRR::Model::Dataset->new();
    for my $et ( '', 'RNA-Seq', ) {
        $input_ds->add_raw_data(
            EpiRR::Model::RawData->new(
                experiment_type => $et,
                primary_id      => 'rd1',
                data_type       => '1',
            )
        );
    }
    my $errors = [];
    my $status = $ds->experimental_completeness( $input_ds, $errors );

    is_deeply(
        $errors,
        [ 'No experiment type for rd1', ],
        "No experiment type generates error"
    );
}

{
    my $errors  = [];
    my $input_s = [
        EpiRR::Model::Sample->new(
            sample_id => 's1',
            meta_data => { donor_id => 'd1' }
        ),
        EpiRR::Model::Sample->new(
            sample_id => 's1',
            meta_data => { donor_id => 'd2' }
        )
    ];

    my $type = $ds->composition( $input_s, $errors );

    is( $type, 'Composite', "Composite" );
    is_deeply( $errors, [], "No errors" );
}

{
    my $errors  = [];
    my $input_s = [
        EpiRR::Model::Sample->new(
            sample_id => 's1',
            meta_data => { pool_id => 'p1' }
        ),
        EpiRR::Model::Sample->new(
            sample_id => 's2',
            meta_data => { pool_id => 'p1' }
        )
    ];

    my $type = $ds->composition( $input_s, $errors );

    is( $type, 'Pooled samples', "Pooled samples" );
    is_deeply( $errors, [], "No errors" );
}

{
    my $errors  = [];
    my $input_s = [
        EpiRR::Model::Sample->new(
            sample_id => 's1',
            meta_data => {}
        ),
    ];

    my $type = $ds->composition( $input_s, $errors );

    is_deeply(
        $errors,
        [
            'No donor_id/pool_id/line found for sample s1',
            'No donor/line/pool information for dataset'
        ],
        "No donor id generates error"
    );
}

done_testing();
