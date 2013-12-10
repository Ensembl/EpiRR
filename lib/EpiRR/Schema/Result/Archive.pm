use utf8;
package EpiRR::Schema::Result::Archive;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

EpiRR::Schema::Result::Archive

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<archive>

=cut

__PACKAGE__->table("archive");

=head1 ACCESSORS

=head2 archive_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 10

=head2 full_name

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=cut

__PACKAGE__->add_columns(
  "archive_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 10 },
  "full_name",
  { data_type => "varchar", is_nullable => 1, size => 128 },
);

=head1 PRIMARY KEY

=over 4

=item * L</archive_id>

=back

=cut

__PACKAGE__->set_primary_key("archive_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<full_name>

=over 4

=item * L</full_name>

=back

=cut

__PACKAGE__->add_unique_constraint("full_name", ["full_name"]);

=head2 C<name>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("name", ["name"]);

=head1 RELATIONS

=head2 raw_datas

Type: has_many

Related object: L<EpiRR::Schema::Result::RawData>

=cut

__PACKAGE__->has_many(
  "raw_datas",
  "EpiRR::Schema::Result::RawData",
  { "foreign.archive_id" => "self.archive_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2013-12-10 14:25:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Tnjc1hlfpPjBq6CAxUTGjg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
