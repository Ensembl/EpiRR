# Copyright 2014 European Molecular Biology Laboratory - European Bioinformatics Institute
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
package EpiRR::Roles::InputParser;

use Moose::Role;
use Carp;
with 'EpiRR::Roles::HasErrors';

requires 'parse';

has 'string'      => ( is => 'rw', isa => 'Maybe[Str]' );
has 'file_path'   => ( is => 'rw', isa => 'Maybe[Str]' );
has 'file_handle' => ( is => 'rw', isa => 'Maybe[FileHandle]' );
has 'dataset'     => (
    is      => 'rw',
    isa     => 'EpiRR::Model::Dataset',
    default => sub { EpiRR::Model::Dataset->new() },
    lazy    => 1,
);

sub _close {
    my ($self) = @_;
    close $self->file_handle();
    $self->file_handle(undef);
}

sub _open {
    my ($self) = @_;
    my $file_path = $self->file_path();
    open my $fh, '<', $file_path or croak("Could not open $file_path: $!");
    $self->file_handle($fh);
}

sub add_error {
    my ( $self, $text ) = @_;

    if ( $self->file_handle() ) {
        $text .= ' at line ';
        $text .= $.; # $. is the line number of the last accessed file handle
    }

    $self->push_error($text);
}

1;
