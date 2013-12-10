#!/usr/bin/env perl
use warnings;
use strict;

BEGIN {
    use FindBin qw/$Bin/;
    use lib "$Bin/lib";
}

use Test::More;
use EpiRR::DB::TestDB;
use Data::Dumper;

my $test_db = EpiRR::DB::TestDB->new();
my $schema  = $test_db->build_up();
$test_db->populate_basics();

#Archive
my $archive = $schema->archive()->find( { name => $test_db->archive_name } );
ok( defined $archive, 'Archive retrieved' );
is( $archive->name, $test_db->archive_name, "Archive name" ) if $archive;
is( $archive->full_name, $test_db->archive_full_name, "Archive full name" )
  if $archive;

#Status
my $status = $schema->status()->find( { name => $test_db->status_name } );
ok( defined $status, 'Status retrived' );
is( $status->name, $test_db->status_name, 'Status name' ) if ($status);

#Project
my $project = $schema->project()->find( { name => $test_db->project_name } );
ok( defined $project, 'Project retrieved' );
is( $project->name(), $test_db->project_name, 'Project name' ) if ($project);
is( $project->id_prefix(), $test_db->project_prefix, 'Project prefix' )
  if ($project);

#Type
my $type = $schema->type()->find( { name => $test_db->type_name } );
ok( defined $type, 'Type retrieved' );
is( $type->name(), $test_db->type_name(), 'Type name' ) if ($type);

#Dataset
my $dataset =
  $schema->dataset()->create( { project_id => $project->project_id() } );

my $expected_accession = 'TPX00000001';

is( $dataset->accession(), $expected_accession, 'accession number generated' );

my $ds_again = $schema->dataset()->find( { accession => $expected_accession } );

ok( defined $ds_again, 'Dataset retrieved by accession' );
ok( $ds_again->project(), 'Project populated' ) if ($ds_again);
is( $ds_again->project()->name(), $test_db->project_name, 'Project name match' )
  if ($ds_again);

#Dataset version

test_versioning( 'TPX00000001.1', $schema, $dataset );
my $dsv2 = test_versioning( 'TPX00000001.2', $schema, $dataset );
my $dsv1 =
  $schema->dataset_version()->find( { full_accession => 'TPX00000001.1' } );

ok( $dsv1, "Old dataset version retrieved" );
ok( !$dsv1->is_current(), "Old Dataset Version is not current" ) if $dsv1;
ok( $dsv2->is_current(),  "New Dataset Version is current" )     if $dsv2;

SKIP: {
    skip "No dataset version to attach objects to", 4 unless $dsv2;

    $schema->meta_data()->create(
        {
            dataset_version_id => $dsv2->dataset_version_id(),
            name               => 'foo',
            value              => 'bar'
        }
    );
    my $md =
      $schema->meta_data()
      ->find( { dataset_version_id => $dsv2->dataset_version_id() } );
    ok( $md, "Retrieved meta data" );
    is( $md->name(),  'foo', "Expected meta data name" )  if $md;
    is( $md->value(), 'bar', "Expected meta data value" ) if $md;

    $dsv2->create_related(
        'raw_datas',
        {
            archive_id          => $archive->archive_id(),
            primary_accession   => 'a',
            secondary_accession => 'b',
            archive_url         => 'c'
        }
    );
    my $rd =
      $schema->raw_data()
      ->find( { dataset_version_id => $dsv2->dataset_version_id() } );
    ok( $rd, "Retrived raw data" );
    is( $rd->archive->name(), $archive->name(), "Expected raw data archive" )
      if $rd;
    is( $rd->primary_accession(), 'a', "Expected raw data primary id" ) if $rd;
    is( $rd->secondary_accession(), 'b', "Expected raw data secondary id" )
      if $rd;
    is( $rd->archive_url(), 'c', "Expected raw data archive url" ) if $rd;
}

done_testing();

sub test_versioning {
    my ( $expected_full_accession, $schema, $dataset ) = @_;

    my $status = $schema->status()->find( { name => $test_db->status_name } );
    my $type = $schema->type()->find( { name => $test_db->type_name } );
    my $dataset_version = $schema->dataset_version()->create(
        {
            dataset => $dataset,
            status  => $status,
            type    => $type
        }
    );

    my $dsv =
      $schema->dataset_version()
      ->find( { full_accession => $expected_full_accession } );

    ok( defined $dsv, "Dataset version $expected_full_accession retrieved" );
    is( $dsv->full_accession, $expected_full_accession,
        "Dataset accession $expected_full_accession correct" )
      if $dsv;

    return $dsv;
}

