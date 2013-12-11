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

with 'EpiRR::Roles::HasMetaData';

has 'project' => (
    is        => 'rw',
    isa       => 'Maybe[Str]',
    default   => '',
    predicate => 'has_project'
);
has 'status' =>
  ( is => 'rw', isa => 'Maybe[Str]', default => '', predicate => 'has_status' );
has 'accession' => (
    is        => 'rw',
    isa       => 'Maybe[Str]',
    default   => '',
    predicate => 'has_accession'
);
has 'local_name'  => ( is => 'rw', isa => 'Maybe[Str]', default => '' );
has 'description' => ( is => 'rw', isa => 'Maybe[Str]', default => '' );

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

__PACKAGE__->meta->make_immutable;
1;
