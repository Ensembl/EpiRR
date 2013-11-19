use utf8;
package EpiRR::Model::Result::DatasetVersion;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

EpiRR::Model::Result::DatasetVersion

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<dataset_version>

=cut

__PACKAGE__->table("dataset_version");

=head1 ACCESSORS

=head2 dataset_version_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 dataset_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 version

  data_type: 'integer'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 is_current

  data_type: 'tinyint'
  is_nullable: 0

=head2 local_name

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 512

=head2 full_accession

  data_type: 'varchar'
  is_nullable: 0
  size: 20

=head2 status

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 10

=cut

__PACKAGE__->add_columns(
  "dataset_version_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "dataset_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "version",
  { data_type => "integer", extra => { unsigned => 1 }, is_nullable => 0 },
  "is_current",
  { data_type => "tinyint", is_nullable => 0 },
  "local_name",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 512 },
  "full_accession",
  { data_type => "varchar", is_nullable => 0, size => 20 },
  "status",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 10 },
);

=head1 PRIMARY KEY

=over 4

=item * L</dataset_version_id>

=back

=cut

__PACKAGE__->set_primary_key("dataset_version_id");

=head1 RELATIONS

=head2 dataset

Type: belongs_to

Related object: L<EpiRR::Model::Result::Dataset>

=cut

__PACKAGE__->belongs_to(
  "dataset",
  "EpiRR::Model::Result::Dataset",
  { dataset_id => "dataset_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 meta_datas

Type: has_many

Related object: L<EpiRR::Model::Result::MetaData>

=cut

__PACKAGE__->has_many(
  "meta_datas",
  "EpiRR::Model::Result::MetaData",
  { "foreign.dataset_version_id" => "self.dataset_version_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 raw_datas

Type: has_many

Related object: L<EpiRR::Model::Result::RawData>

=cut

__PACKAGE__->has_many(
  "raw_datas",
  "EpiRR::Model::Result::RawData",
  { "foreign.dataset_version_id" => "self.dataset_version_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 status

Type: belongs_to

Related object: L<EpiRR::Model::Result::Status>

=cut

__PACKAGE__->belongs_to(
  "status",
  "EpiRR::Model::Result::Status",
  { status => "status" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2013-11-11 12:50:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cUl88SK/7rAuFwP5GmO41g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
use Class::Method::Modifiers;
use Carp;

=head2 before insert
  Before insertion, the version number and full accession will be determined 
  and added to the object
=cut
before 'insert' => sub {
  my ($self) = @_;
  
  my $dataset = $self->dataset();
  
  if (! $self->version){
    my $version_number = $dataset->next_version();
    $self->version($version_number);
  }

  my $full_accession = $dataset->accession() . '.' . $self->version();
  $self->full_accession($full_accession);
};

1;
