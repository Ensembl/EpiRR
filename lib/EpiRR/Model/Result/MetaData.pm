use utf8;
package EpiRR::Model::Result::MetaData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

EpiRR::Model::Result::MetaData

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<meta_data>

=cut

__PACKAGE__->table("meta_data");

=head1 ACCESSORS

=head2 meta_data_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 dataset_version_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 256

=head2 value

  data_type: 'varchar'
  is_nullable: 0
  size: 4000

=cut

__PACKAGE__->add_columns(
  "meta_data_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "dataset_version_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 256 },
  "value",
  { data_type => "varchar", is_nullable => 0, size => 4000 },
);

=head1 PRIMARY KEY

=over 4

=item * L</meta_data_id>

=back

=cut

__PACKAGE__->set_primary_key("meta_data_id");

=head1 RELATIONS

=head2 dataset_version

Type: belongs_to

Related object: L<EpiRR::Model::Result::DatasetVersion>

=cut

__PACKAGE__->belongs_to(
  "dataset_version",
  "EpiRR::Model::Result::DatasetVersion",
  { dataset_version_id => "dataset_version_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2013-11-11 12:50:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iXOuY2F510psWeyZChaBjw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
