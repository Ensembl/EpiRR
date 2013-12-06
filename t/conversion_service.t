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

my $test_db = EpiRR::DB::TestDB->new();
my $schema  = $test_db->build_up();
$test_db->populate_basics();

my $experiment_id = 'X1';

my $mock_aa =
  new Test::MockObject::Extends( EpiRR::Service::ArchiveAccessorStub->new() );

my $cs = EpiRR::Service::ConversionService->new(
    schema           => $schema,
    archive_services => { $test_db->archive_name() => $mock_aa, }
);
my $raw_data_input = EpiRR::Model::RawData->new(
    archive    => $test_db->archive_name(),
    primary_id => $experiment_id
);
my $test_input = EpiRR::Model::Dataset->new(
    project  => $test_db->project_name(),
    raw_data => [$raw_data_input],
);

$mock_aa->mock_expect_once( 'lookup_raw_data', 'admin',
    args => [$raw_data_input] );
my $errors = [];

my $test_output = $cs->simple_to_db( $test_input, $errors );

$mock_aa->mock_tally();

ok( $test_output->dataset(), "Has a project" );
is(
    $test_output->dataset()->project()->name(),
    $test_db->project_name(),
    "Correct project"
) if ( $test_output->dataset() );

my @raw_data = $test_output->raw_datas();
is( scalar(@raw_data), 1, "One raw data" );
my $raw_data = pop @raw_data;

done_testing();
