use utf8;
package EpiRR::Schema::Result::Status;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

EpiRR::Schema::Result::Status

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<status>

=cut

__PACKAGE__->table("status");

=head1 ACCESSORS

=head2 status

  data_type: 'varchar'
  is_nullable: 0
  size: 10

=cut

__PACKAGE__->add_columns(
  "status",
  { data_type => "varchar", is_nullable => 0, size => 10 },
);

=head1 PRIMARY KEY

=over 4

=item * L</status>

=back

=cut

__PACKAGE__->set_primary_key("status");

=head1 RELATIONS

=head2 dataset_versions

Type: has_many

Related object: L<EpiRR::Schema::Result::DatasetVersion>

=cut

__PACKAGE__->has_many(
  "dataset_versions",
  "EpiRR::Schema::Result::DatasetVersion",
  { "foreign.status" => "self.status" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2013-11-11 12:50:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PWFiLnpf7tcdmWYIMl/4zA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
