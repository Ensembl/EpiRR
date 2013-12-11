use utf8;
package EpiRR::Schema::Result::DatasetVersion;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

EpiRR::Schema::Result::DatasetVersion

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

=head2 status_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  extra: {unsigned => 1}
  is_foreign_key: 1
  is_nullable: 0

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

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
  "status_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "type_id",
  {
    data_type => "integer",
    extra => { unsigned => 1 },
    is_foreign_key => 1,
    is_nullable => 0,
  },
  "created",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</dataset_version_id>

=back

=cut

__PACKAGE__->set_primary_key("dataset_version_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<full_accession>

=over 4

=item * L</full_accession>

=back

=cut

__PACKAGE__->add_unique_constraint("full_accession", ["full_accession"]);

=head1 RELATIONS

=head2 dataset

Type: belongs_to

Related object: L<EpiRR::Schema::Result::Dataset>

=cut

__PACKAGE__->belongs_to(
  "dataset",
  "EpiRR::Schema::Result::Dataset",
  { dataset_id => "dataset_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 meta_datas

Type: has_many

Related object: L<EpiRR::Schema::Result::MetaData>

=cut

__PACKAGE__->has_many(
  "meta_datas",
  "EpiRR::Schema::Result::MetaData",
  { "foreign.dataset_version_id" => "self.dataset_version_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 raw_datas

Type: has_many

Related object: L<EpiRR::Schema::Result::RawData>

=cut

__PACKAGE__->has_many(
  "raw_datas",
  "EpiRR::Schema::Result::RawData",
  { "foreign.dataset_version_id" => "self.dataset_version_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 status

Type: belongs_to

Related object: L<EpiRR::Schema::Result::Status>

=cut

__PACKAGE__->belongs_to(
  "status",
  "EpiRR::Schema::Result::Status",
  { status_id => "status_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);

=head2 type

Type: belongs_to

Related object: L<EpiRR::Schema::Result::Type>

=cut

__PACKAGE__->belongs_to(
  "type",
  "EpiRR::Schema::Result::Type",
  { type_id => "type_id" },
  { is_deferrable => 1, on_delete => "RESTRICT", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2013-12-10 13:14:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ukaEZrIFofzROyFnBMeVRw

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
use Class::Method::Modifiers;
use Carp;

=head2 before insert
  Before insertion, the version number and full accession will be determined 
  and added to the object
=cut
before 'insert' => sub {
  my ($self) = @_;
  
  my $dataset = $self->dataset();
  if (! $self->version()){

    my $new_version = $self->update_version();
    $self->version($new_version);
    $self->is_current(1);
  }
  my $full_accession = $dataset->accession() . '.' . $self->version();
  $self->full_accession($full_accession);
};

=head2 update_version

 Find the current DatasetVersion. Remove it's is_current flag and return the next version number to use.

=cut

sub update_version {
    my ($self) = @_;
    
    my $schema = $self->result_source()->schema();
    my $current = $schema->dataset_version()->find({dataset_id => $self->dataset_id(),is_current => 1});

    my $version_number = 0;
    if ($current) {
      $version_number = $current->version();
      $current->is_current(0);
      $current->update();
    }

    return $version_number+1;
}

1;
