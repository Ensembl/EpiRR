use utf8;

package EpiRR::Model::Result::Dataset;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

EpiRR::Model::Result::Dataset

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<dataset>

=cut

__PACKAGE__->table("dataset");

=head1 ACCESSORS

=head2 dataset_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 project_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 accession

  data_type: 'varchar'
  is_nullable: 1
  size: 18

=cut

__PACKAGE__->add_columns(
    "dataset_id",
    {
        data_type         => "integer",
        extra             => { unsigned => 1 },
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    "project_id",
    {
        data_type      => "integer",
        extra          => { unsigned => 1 },
        is_foreign_key => 1,
        is_nullable    => 0,
    },
    "accession",
    { data_type => "varchar", is_nullable => 1, size => 18 },
);

=head1 PRIMARY KEY

=over 4

=item * L</dataset_id>

=back

=cut

__PACKAGE__->set_primary_key("dataset_id");

=head1 RELATIONS

=head2 dataset_versions

Type: has_many

Related object: L<EpiRR::Model::Result::DatasetVersion>

=cut

__PACKAGE__->has_many(
    "dataset_versions",
    "EpiRR::Model::Result::DatasetVersion",
    { "foreign.dataset_id" => "self.dataset_id" },
    { cascade_copy         => 0, cascade_delete => 0 },
);

=head2 project

Type: belongs_to

Related object: L<EpiRR::Model::Result::Project>

=cut

__PACKAGE__->belongs_to(
    "project",
    "EpiRR::Model::Result::Project",
    { project_id    => "project_id" },
    { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

# Created by DBIx::Class::Schema::Loader v0.07037 @ 2013-11-11 12:50:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:G5dk0ZrX1+2PIDLZv4M9bQ
use Carp;

sub current_version {
  return $_[0]->dataset_versions({is_current => 1})->single();
}

sub create_accession {
    my ($self) = @_;

    croak 'Accession is already populated: ' . $self->accession()
      if $self->accession;
    croak 'Project is not populated'
      unless $self->project_id() && $self->project();
    croak 'Dataset ID is not populated' unless $self->dataset_id();

    my $accession =
      $self->project()->id_prefix() . sprintf( "%08d", $self->dataset_id() );
    $self->accession($accession);
}

sub next_version {
    my ($self) = @_;

    my $version_number = 1;
    my $dsv = $self->current_version();
    if ($dsv) {
        $version_number = $dsv->version() + 1;
        $dsv->is_current(0);
        $dsv->update();
    }
    return $version_number;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
