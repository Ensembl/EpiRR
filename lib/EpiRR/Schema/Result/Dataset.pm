use utf8;

package EpiRR::Schema::Result::Dataset;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

EpiRR::Schema::Result::Dataset

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

Related object: L<EpiRR::Schema::Result::DatasetVersion>

=cut

__PACKAGE__->has_many(
    "dataset_versions",
    "EpiRR::Schema::Result::DatasetVersion",
    { "foreign.dataset_id" => "self.dataset_id" },
    { cascade_copy         => 0, cascade_delete => 0 },
);

=head2 project

Type: belongs_to

Related object: L<EpiRR::Schema::Result::Project>

=cut

__PACKAGE__->belongs_to(
    "project",
    "EpiRR::Schema::Result::Project",
    { project_id    => "project_id" },
    { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

# Created by DBIx::Class::Schema::Loader v0.07037 @ 2013-11-11 12:50:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:G5dk0ZrX1+2PIDLZv4M9bQ
use Carp;
use Class::Method::Modifiers;

=head2 after insert

  After the record has been inserted into the database, the accession will 
  be created based on the project id prefix and the dataset id (primary key).
  The record will then be updated. 

=cut

after 'insert' => sub {
    my ($self) = @_;

    if ( !$self->accession ) {
        croak 'Project is not populated'
          unless $self->project_id() && $self->project();
        croak 'Dataset ID is not populated' unless $self->dataset_id();
        my $accession =
          $self->project()->id_prefix()
          . sprintf( "%08d", $self->dataset_id() );
        $self->accession($accession);
        $self->update();

    }
};

1;
