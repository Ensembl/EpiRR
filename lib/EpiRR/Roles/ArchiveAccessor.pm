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
package EpiRR::Roles::ArchiveAccessor;

use Moose::Role;

requires 'lookup_raw_data';

has 'supported_archives' => (
    traits   => ['Array'],
    is       => 'rw',
    isa      => 'ArrayRef[Str]',
    required => 1,
    handles  => { all_supported_archives => 'elements' }
);

sub handles_archive {
    my ( $self, $archive ) = @_;

    my @matches = grep { $_ eq $archive } $self->all_supported_archives();

    if (@matches) {
        return 1;
    }
    else {
        return undef;
    }
}

1;
