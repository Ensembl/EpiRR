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
package EpiRR::Model::Dataset;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

extends 'EpiRR::Model::DatasetSummary';
with 'EpiRR::Roles::HasMetaData';

has 'raw_data' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[EpiRR::Model::RawData]',
    handles => {
        all_raw_data   => 'elements',
        add_raw_data   => 'push',
        map_raw_data   => 'map',
        raw_data_count => 'count',
        has_raw_data   => 'count',
        get_raw_data   => 'get',
    },
    default => sub { [] },
);
has 'is_current' => ( is => 'rw', isa => 'Bool', default => '' );

sub to_hash {
    my ($self) = @_;

    my @raw_data = map { $_->to_hash() } $self->all_raw_data();
    my %meta_data = $self->all_meta_data();

    return {
        project        => $self->project,
        status         => $self->status,
        type           => $self->type,
        accession      => $self->accession,
        local_name     => $self->local_name,
        description    => $self->description,
        full_accession => $self->full_accession,
        version        => $self->version,
        raw_data       => \@raw_data,
        meta_data      => \%meta_data,
        is_current     => $self->is_current ? 1 : 0,
    };
}

__PACKAGE__->meta->make_immutable;
1;
