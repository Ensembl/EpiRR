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
use EpiRR::Parser::JsonParser;
use JSON;
use File::Basename;
{
    my $parser   = parser('rm_small.json');
    my $expected = EpiRR::Model::Dataset->new(
        project     => 'NIH Roadmap',
        description => 'CD14 primary cells',
        local_name  => 'CD14 primary cells small test',
        raw_data    => [
            EpiRR::Model::RawData->new(
                archive    => 'GEO',
                primary_id => 'GSM665840'
            ),
            EpiRR::Model::RawData->new(
                archive    => 'GEO',
                primary_id => 'GSM1220575'
            ),
        ]
    );
    $parser->parse();
    is_deeply( $parser->dataset(), $expected, 'Parse JSON file' );
}

{
    my $parser   = parser('rm_duplicates.json');
    $parser->parse();
    is_deeply(
        $parser->errors,
        [
            'Duplicate raw_data values detected',
        ],
        'Duplicate raw data values'
    );
}

{
    my $parser   = parser('rm_cd14.txt');
    $parser->parse();
    is_deeply(
        $parser->errors,
        [
            'Not a valid JSON file',
        ],
        'Not a valid JSON file'
    );
}

{
    my $dataset = EpiRR::Model::Dataset->new(
        project        => 'project',
        status         => 'ok',
        type           => 'finished',
        accession      => 'foo1',
        full_accession => 'foo1.1',
        version        => 1,
        local_name     => 'foo1_local',
        description    => 'some data',
        raw_data       => [
            EpiRR::Model::RawData->new(
                archive         => 'myarchive',
                primary_id      => 'p1',
                secondary_id    => 's1',
                archive_url     => 'www.foo.bar',
                experiment_type => 'rna-seq',
                assay_type       => 'rna',
            ),
            EpiRR::Model::RawData->new(
                archive         => 'myarchive',
                primary_id      => 'p2',
                secondary_id    => 's2',
                archive_url     => 'www.foo.bar',
                experiment_type => 'chip-seq',
                assay_type       => 'chip',
            )
        ],
        meta_data => { tag => 'value' },
    );

    my $actual        = $dataset->to_hash();
    my $expected_hash = {
        project        => 'project',
        status         => 'ok',
        type           => 'finished',
        accession      => 'foo1',
        full_accession => 'foo1.1',
        version        => 1,
        local_name     => 'foo1_local',
        description    => 'some data',
        raw_data       => [
            {
                archive         => 'myarchive',
                primary_id      => 'p1',
                secondary_id    => 's1',
                archive_url     => 'www.foo.bar',
                experiment_type => 'rna-seq',
                assay_type       => 'rna',
            },
            {
                archive         => 'myarchive',
                primary_id      => 'p2',
                secondary_id    => 's2',
                archive_url     => 'www.foo.bar',
                experiment_type => 'chip-seq',
                assay_type       => 'chip',
            }
        ],
        meta_data => { tag => 'value' },
    };
    is_deeply( $actual, $expected_hash, "Convert dataset to hash" );

    my $json = encode_json $dataset->TO_JSON();

    my $parser = EpiRR::Parser::JsonParser->new( string => $json );

    my $deserialized_datasets = $parser->parse();

    is_deeply( $deserialized_datasets, $dataset, "Deserialize JSON to object" );

}

done_testing();

sub parser {
    my ($file)    = @_;
    my $dir       = dirname(__FILE__);
    my $test_file = $dir . '/datasets/' . $file;

    return EpiRR::Parser::JsonParser->new( file_path => $test_file );
}
