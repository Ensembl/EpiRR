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
use utf8;

package EpiRR::Parser::JsonParser;

use strict;
use warnings;
use Carp;
use Moose;
use namespace::autoclean;

use EpiRR::Model::Dataset;
use EpiRR::Model::RawData;

use Moose;
use JSON;
use Carp;

with 'EpiRR::Roles::InputParser';

=head1 NAME

EpiRR::Parser::JSONParser

Parses JSON to produce EpiRR::Model::Dataset objects.



=cut

sub parse {
    my ($self) = @_;

    my $json      = $self->_get_string();
    my $perl_data = decode_json($json);
    $self->convert_dataset($perl_data);
}

sub _get_string {
    my ($self) = @_;
    
    my $string = $self->string();
    
    if (!$string) {
        local $/ = undef;
        $self->_open();
        my $fh = $self->file_handle();
        $string = <$fh>;
        $self->_close();
    }

    return $string;

}

sub convert_dataset {
    my ( $self, $dataset_hashref ) = @_;

    my %dataset = %$dataset_hashref;

    my $rawdata_ref = delete $dataset{raw_data};
    my $raw_data = [ map { EpiRR::Model::RawData->new(%$_) } @$rawdata_ref ];

    $dataset{raw_data} = $raw_data;

    $self->dataset( EpiRR::Model::Dataset->new(%dataset) );
}

__PACKAGE__->meta->make_immutable;

1;
