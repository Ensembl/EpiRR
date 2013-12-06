use warnings;
use strict;

use EpiRR::Schema;
use Getopt::Long;
use Croak;

use Data::Dumper;


my ( $db_url, $db_user, $db_pass, %db_params, );
my ( $project_name, $dataset_accession );

GetOptions(
    "dburl=s"     => \$db_url,
    "dbuser=s"    => \$db_user,
    "dbpass=s"    => \$db_pass,
    "dbparam=s"   => \%db_params,
    "project=s"   => \$project_name,
    "accession=s" => \$dataset_accession,
);

my $schema = EpiRR::Schema->connect( $db_url, $db_user, $db_pass );



$schema->txn_begin();

my ($dataset,$accession);

if (defined $dataset_accession) {
  $dataset = $schema->dataset()->find({accession => $dataset_accession});
  die "No accession found for $dataset_accession" if (! $dataset);
  
  if (! $dataset->project_id == $project->project_id) {
    my $ds_project_name = $dataset->project()->name();
    my $project_name = $project->name();
    die "Project mismatch between dataset $dataset_accession ($ds_project_name) vs. parameter ($project_name)";
  }
}
else {
  $dataset = $schema->dataset()->create({ project_id => $project->project_id() });
  $dataset->create_accession();
  $dataset->update();
  print 'New dataset accessioned:'.$dataset->accession();
}





$schema->txn_commit();




