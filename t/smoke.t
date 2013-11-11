use warnings;
use strict;

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
my $status = $schema->status()->find( $test_db->status_name );
ok( defined $status, 'Status retrived' );
is( $status->status, $test_db->status_name, 'Status name' ) if ($status);

#Project
my $project = $schema->project()->find( { name => $test_db->project_name } );
ok( defined $project, 'Project retrieved' );
is( $project->name(), $test_db->project_name, 'Project name' ) if ($project);
is( $project->id_prefix(), $test_db->project_prefix, 'Project prefix' )
  if ($project);

#Dataset
my $dataset =
  $schema->dataset()->create( { project_id => $project->project_id() } );
$dataset->create_accession();
$dataset->update();

my $expected_accession = 'TPX00000001';

is( $dataset->accession(), $expected_accession, 'accession number generated' );

my $ds_again = $schema->dataset()->find( { accession => $expected_accession } );

ok( defined $ds_again, 'Dataset retrieved by accession' );
ok( $ds_again->project(), 'Project populated' ) if ($ds_again);
is( $ds_again->project()->name(), $test_db->project_name, 'Project name match' )
  if ($ds_again);

#Dataset version
my $version_number = $dataset->next_version();
my $full_accession = $dataset->accession() . '.' . $version_number;

my $dataset_version = $schema->dataset_version()->create(
    {
        dataset_id     => $dataset->dataset_id(),
        version        => $version_number,
        full_accession => $full_accession,
        is_current     => 1,
        status         => $test_db->status_name(),
    }
);

my $dsv =
  $schema->dataset_version()->find( { full_accession => $full_accession } );
ok( defined $dsv, "Dataset version retrieved" );

done_testing();
