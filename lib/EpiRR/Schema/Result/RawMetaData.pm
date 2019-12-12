use utf8;
package EpiRR::Schema::Result::RawMetaData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

EpiRR::Schema::Result::RawMetaData

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<raw_meta_data>

=cut

__PACKAGE__->table("raw_meta_data");

=head1 ACCESSORS

=head2 raw_meta_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 raw_data_id

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
  "raw_meta_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "raw_data_id",
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

=item * L</raw_meta_id>

=back

=cut

__PACKAGE__->set_primary_key("raw_meta_id");

=head1 RELATIONS

=head2 raw_data

Type: belongs_to

Related object: L<EpiRR::Schema::Result::RawData>

=cut

__PACKAGE__->belongs_to(
  "raw_data",
  "EpiRR::Schema::Result::RawData",
  { raw_data_id => "raw_data_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-12-08 10:39:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yiwRGO+kIhJSXWusxxVhRA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
