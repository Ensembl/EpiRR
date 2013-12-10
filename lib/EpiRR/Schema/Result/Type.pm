use utf8;
package EpiRR::Schema::Result::Type;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

EpiRR::Schema::Result::Type

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<type>

=cut

__PACKAGE__->table("type");

=head1 ACCESSORS

=head2 type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 10

=cut

__PACKAGE__->add_columns(
  "type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
  },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 10 },
);

=head1 PRIMARY KEY

=over 4

=item * L</type_id>

=back

=cut

__PACKAGE__->set_primary_key("type_id");

=head1 RELATIONS

=head2 dataset_versions

Type: has_many

Related object: L<EpiRR::Schema::Result::DatasetVersion>

=cut

__PACKAGE__->has_many(
  "dataset_versions",
  "EpiRR::Schema::Result::DatasetVersion",
  { "foreign.type_id" => "self.type_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2013-12-10 13:14:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:N0uvwnGfIU6gLeCqiJVv4g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
