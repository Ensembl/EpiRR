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

=head2 raw_data_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_auto_increment: 1
  is_nullable: 0

=head2 dataset_version_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 primary_accession

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 secondary_accession

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=head2 assay_type

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 experiment_type

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 archive_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 archive_url

  data_type: 'varchar'
  is_nullable: 1
  size: 512

=cut

__PACKAGE__->add_columns(
  "raw_data_id",
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
  "primary_accession",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "secondary_accession",
  { data_type => "varchar", is_nullable => 1, size => 64 },
  "assay_type",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "experiment_type",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "archive_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "archive_url",
  { data_type => "varchar", is_nullable => 1, size => 512 },
);

=head1 PRIMARY KEY

=over 4

=item * L</raw_data_id>

=back

=cut

__PACKAGE__->set_primary_key("raw_data_id");

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

=head2 raw_meta_datas

Type: has_many

Related object: L<EpiRR::Schema::Result::RawMetaData>

=cut

__PACKAGE__->has_many(
  "raw_meta_datas",
  "EpiRR::Schema::Result::RawMetaData",
  { "foreign.raw_data_id" => "self.raw_data_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-12-08 10:39:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:w61nD1YYCA3uyxP1IMTfgA

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
