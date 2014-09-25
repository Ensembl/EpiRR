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

use EpiRR::Service::CommonMetaDataBuilder;
use EpiRR::Model::Sample;
use Test::More;

my $b = EpiRR::Service::CommonMetaDataBuilder->new( required_meta_data => [] );

{
    my $input = [
        EpiRR::Model::Sample->new(
            sample_id => 'S1',
            meta_data => {
                foo              => 'bar',
                strudel          => 'apple',
                attr             => 'value',
                species          => 'hs',
                biomaterial_type => 'bt'
            },
        ),
        EpiRR::Model::Sample->new(
            sample_id => 'S2',
            meta_data => { foo => 'bar', noodles => 'egg', attr => 'value' },
        )
    ];
    my $errors   = [];
    my %expected = ( foo => 'bar', attr => 'value' );
    my %actual   = $b->build_meta_data( $input, $errors );

    is_deeply( \%actual, \%expected, 'Common meta data returned' );
    is_deeply( $errors, [], 'No errors expected' );
}

{
    my $input = [
        EpiRR::Model::Sample->new(
            sample_id => 'S1',
            meta_data => { foo => 'BAR', strudel => 'apple', attr => '' },
        ),
        EpiRR::Model::Sample->new(
            sample_id => 'S2',
            meta_data => { foo => 'bar', noodles => 'egg', attr => 'value' },
        )
    ];
    my $errors = [];
    my %actual = $b->build_meta_data( $input, $errors );

    is_deeply( \%actual, {}, 'No common meta data returned' );
    is_deeply(
        $errors,
        ['No common meta data found between samples'],
        '"No common meta data" error expected'
    );
}

$b =
  EpiRR::Service::CommonMetaDataBuilder->new(
    required_meta_data => [ ['foo'], [ 'pool_id', 'donor_id', 'line' ], ] );

{
    my $input = [
        EpiRR::Model::Sample->new(
            sample_id => 'S1',
            meta_data => { foo => 'BAR', line => 'apple' },
        ),
        EpiRR::Model::Sample->new(
            sample_id => 'S2',
            meta_data => { foo => 'BAR', line => 'pear' },
        )
    ];
    my $errors = [];
    my %actual = $b->build_meta_data( $input, $errors );

    is_deeply( \%actual, {foo => 'BAR'}, 'Some common meta data returned' );
    is_deeply(
        $errors,
        ['Common meta data should include one of the following: pool_id, donor_id, line'],
        'Reference epigenome metadata error message expected'
    );
}




done_testing();

