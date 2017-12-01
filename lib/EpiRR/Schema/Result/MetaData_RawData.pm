use utf8;
package EpiRR::Schema::Result::RawData;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

EpiRR::Schema::Result::RawData

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<raw_data>

=cut

__PACKAGE__->table("raw_data");

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

=head2 archive

Type: belongs_to

Related object: L<EpiRR::Schema::Result::Archive>

=cut

__PACKAGE__->belongs_to(
  "archive",
  "EpiRR::Schema::Result::Archive",
  { archive_id => "archive_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 dataset_version

Type: belongs_to

Related object: L<EpiRR::Schema::Result::DatasetVersion>

=cut

__PACKAGE__->belongs_to(
  "dataset_version",
  "EpiRR::Schema::Result::DatasetVersion",
  { dataset_version_id => "dataset_version_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2014-09-25 15:21:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LxSYF0W+CtG/+Tj1+lm/sg

# Copyright 2013 European Molecular Biology Laboratory - European Bioinformatics Institute
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

1;
