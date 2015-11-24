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
package EpiRR::Model::DatasetSummary;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

has 'project' => (
    is        => 'rw',
    isa       => 'Maybe[Str]',
    default   => '',
    predicate => 'has_project'
);
has 'status' => ( is => 'rw', isa => 'Str', default => '', );
has 'type'   => ( is => 'rw', isa => 'Str', default => '', );

has 'accession' => (
    is        => 'rw',
    isa       => 'Maybe[Str]',
    default   => '',
    predicate => 'has_accession'
);
has 'full_accession' => (
    is  => 'rw',
    isa => 'Maybe[Str]',
);
has 'version' => (
    is  => 'rw',
    isa => 'Maybe[Int]',
);

has 'local_name'  => ( is => 'rw', isa => 'Maybe[Str]', default => '' );
has 'description' => ( is => 'rw', isa => 'Maybe[Str]', default => '' );


sub to_hash {
    my ($self) = @_;

    return {
        project        => $self->project,
        status         => $self->status,
        type           => $self->type,
        accession      => $self->accession,
        local_name     => $self->local_name,
        description    => $self->description,
        full_accession => $self->full_accession,
        version        => $self->version,
    };
}

sub TO_JSON {
    my ($self) = @_;
    return $self->to_hash();
}
__PACKAGE__->meta->make_immutable;
1;
