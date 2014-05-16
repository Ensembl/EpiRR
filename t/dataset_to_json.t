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
use strict;
use warnings;

use EpiRR::Model::RawData;
use EpiRR::Model::Dataset;

use Test::More;

{
    my $dataset = EpiRR::Model::Dataset->new(
        project     => 'project',
        status      => 'ok',
        type        => 'finished',
        accession   => 'foo1',
        local_name  => 'foo1_local',
        description => 'some data',
        raw_data    => [
            EpiRR::Model::RawData->new(
                archive         => 'myarchive',
                primary_id      => 'p1',
                secondary_id    => 's1',
                archive_url     => 'www.foo.bar',
                experiment_type => 'rna-seq'
            )
        ],
        meta_data => { tag => 'value' },
    );

    my $actual   = $dataset->to_hash();
    my $expected = {
        project     => 'project',
        status      => 'ok',
        type        => 'finished',
        accession   => 'foo1',
        local_name  => 'foo1_local',
        description => 'some data',
        raw_data    => [
            {
                archive         => 'myarchive',
                primary_id      => 'p1',
                secondary_id    => 's1',
                archive_url     => 'www.foo.bar',
                experiment_type => 'rna-seq'
            }
        ],
        meta_data => { tag => 'value' },
    };
    is_deeply( $actual, $expected, "Convert dataset to hash" );
}

done_testing();
