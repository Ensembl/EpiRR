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

use EpiRR::Service::ConversionService;
use Test::More;
use Test::MockObject::Extends;

BEGIN {
    use FindBin qw/$Bin/;
    use lib "$Bin/lib";
}

use EpiRR::DB::TestDB;
use EpiRR::Service::ArchiveAccessorStub;

use EpiRR::Model::Sample;
use EpiRR::Model::RawData;

use Data::Dumper;

use EpiRR::Service::MetaDataBuilderStub;
use EpiRR::Service::DatasetClassifierStub;

my $test_db = EpiRR::DB::TestDB->new();
my $schema  = $test_db->build_up();
$test_db->populate_basics();

my @experiment_ids = ( 'X1', 'X2' );

my $lookup_called  = 0;
my @aa_return_vals = (
    [
        EpiRR::Model::RawData->new(
            archive         => $test_db->archive_name(),
            primary_id      => $experiment_ids[0],
            experiment_type => 'Type 1',
        ),
        EpiRR::Model::Sample->new(
            sample_id => 'S1',
            meta_data => { foo => 'bar', strudel => 'apple', DONOR_ID => 'a' },
        )
    ],
    [
        EpiRR::Model::RawData->new(
            archive         => $test_db->archive_name(),
            primary_id      => $experiment_ids[1],
            experiment_type => 'Type 2',
        ),
        EpiRR::Model::Sample->new(
            sample_id => 'S2',
            meta_data =>
              { foo => 'bar', noodles => 'canoodles', DONOR_ID => 'b' },
        )
    ]
);

my $mock_aa =
  Test::MockObject::Extends->new( EpiRR::Service::ArchiveAccessorStub->new() );
$mock_aa->mock(
    'lookup_raw_data',
    sub {
        return @{ $aa_return_vals[ $lookup_called++ ] };
    }
);
$mock_aa->mock( 'handles_archive', sub { return 1 } );

my $mock_mdb =
  Test::MockObject::Extends->new( EpiRR::Service::MetaDataBuilderStub->new() );
$mock_mdb->mock(
    'build_meta_data',
    sub {
        return ( foo => 'bar' );
    }
);

my $mock_ds =
  Test::MockObject::Extends->new(
    EpiRR::Service::DatasetClassifierStub->new() );
$mock_ds->mock(
    'determine_classification',
    sub {
        return ( $test_db->status_name(), $test_db->type_name() );
    }
);

my $cs = EpiRR::Service::ConversionService->new(
    schema             => $schema,
    archive_services   => { $test_db->archive_name() => $mock_aa, },
    meta_data_builder  => $mock_mdb,
    dataset_classifier => $mock_ds,
);

my $test_input = EpiRR::Model::Dataset->new(
    project    => $test_db->project_name(),
    local_name => 'our test set',
    raw_data   => [
        EpiRR::Model::RawData->new(
            archive    => $test_db->archive_name(),
            primary_id => $experiment_ids[0]
        ),
        EpiRR::Model::RawData->new(
            archive    => $test_db->archive_name(),
            primary_id => $experiment_ids[1]
        )
    ],
);

my $errors = [];

my $test_output = $cs->user_to_db( $test_input, $errors );

is( $lookup_called, 2, "Called lookup method twice" );

is_deeply( $errors, [], "No errors" );

ok( $test_output->dataset(), "Has a project" );
is(
    $test_output->dataset()->project()->name(),
    $test_db->project_name(),
    "Correct project"
) if ( $test_output->dataset() );
is( $test_output->dataset()->local_name(), 'our test set',
    'local name is set' );

my @output_raw_data = $test_output->raw_datas();
is( scalar(@output_raw_data), 2, "Two raw data" );
my $raw_data = pop @output_raw_data;

my @output_meta_data = $test_output->meta_datas();
is( scalar(@output_meta_data),    1,     "One piece of meta data expected" );
is( $output_meta_data[0]->name(), 'foo', 'Correct meta data attribute' )
  if (@output_meta_data);
is( $output_meta_data[0]->value(), 'bar', 'Correct meta data value' )
  if (@output_meta_data);

my $user_level_output = $cs->db_to_user($test_output);

my $expected_user_level_output = EpiRR::Model::Dataset->new(
    project        => $test_db->project_name(),
    status         => 'Complete',
    meta_data      => { foo => 'bar' },
    type           => 'Single donor',
    full_accession => 'TPX00000001.1',
    accession      => 'TPX00000001',
    version        => 1,
    local_name => 'our test set',
    raw_data   => [
        EpiRR::Model::RawData->new(
            archive         => $test_db->archive_name(),
            primary_id      => $experiment_ids[0],
            secondary_id    => undef,
            archive_url     => undef,
            experiment_type => 'Type 1',
            data_type       => undef,
        ),
        EpiRR::Model::RawData->new(
            archive         => $test_db->archive_name(),
            primary_id      => $experiment_ids[1],
            experiment_type => 'Type 2',
            secondary_id    => undef,
            archive_url     => undef,
            data_type       => undef,
        )
    ],
);

is_deeply( $user_level_output, $expected_user_level_output,
    "Expected output from DB" );

done_testing();

