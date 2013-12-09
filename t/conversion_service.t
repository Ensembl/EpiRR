#!/usr/bin/env perl
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

my $test_db = EpiRR::DB::TestDB->new();
my $schema  = $test_db->build_up();
$test_db->populate_basics();

my @experiment_ids = ( 'X1', 'X2' );

my $lookup_called = 0;
my @aa_return_vals      = (
    [
        EpiRR::Model::RawData->new(
            archive         => $test_db->archive_name(),
            primary_id      => $experiment_ids[0],
            experiment_type => 'Type 1',
        ),
        EpiRR::Model::Sample->new(
            sample_id => 'S1',
            meta_data => { foo => 'bar', strudel => 'apple' },
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
            meta_data => { foo => 'bar', noodles => 'canoodles' },
        )
    ]
);

my $mock_aa =
  new Test::MockObject::Extends( EpiRR::Service::ArchiveAccessorStub->new() );
$mock_aa->mock(
    'lookup_raw_data',
    sub {
        return @{$aa_return_vals[ $lookup_called++ ]};
    }
);

my $cs = EpiRR::Service::ConversionService->new(
    schema           => $schema,
    archive_services => { $test_db->archive_name() => $mock_aa, },
    meta_data_builder =>  EpiRR::Service::CommonMetaDataBuilder->new(),
);

my $test_input = EpiRR::Model::Dataset->new(
    project  => $test_db->project_name(),
    raw_data => [
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

my $test_output = $cs->simple_to_db( $test_input, $errors );

is( $lookup_called, 2, "Called lookup method twice" );

ok( $test_output->dataset(), "Has a project" );
is(
    $test_output->dataset()->project()->name(),
    $test_db->project_name(),
    "Correct project"
) if ( $test_output->dataset() );

my @output_raw_data = $test_output->raw_datas();
is( scalar(@output_raw_data), 2, "Two raw data" );
my $raw_data = pop @output_raw_data;

my @output_meta_data = $test_output->meta_datas();
is( scalar(@output_meta_data),   1,     "One piece of meta data expected" );
is( $output_meta_data[0]->name(), 'foo', 'Correct meta data attribute' )
  if (@output_meta_data);
is( $output_meta_data[0]->value(), 'bar', 'Correct meta data value' )
  if (@output_meta_data);

done_testing();
