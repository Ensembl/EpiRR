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

use Data::Dumper;
use JSON;
use Carp;

=head1 NAME

EpiRR::Parser::JSONParser

Parses JSON to produce EpiRR::Model::Dataset objects.



=cut

sub parse {
    my ( $self, $json ) = @_;

    my $perl_data = decode_json($json);

    if ( ref($perl_data) eq 'HASH' ) {
        $perl_data = [$perl_data];
    }

    if ( ref($perl_data) eq 'ARRAY' ) {
        return [ map { $self->convert_dataset($_) } @$perl_data ];
    }
    else {
        confess("Cannot use decoded data type");
    }

    die Dumper($perl_data);

}

sub convert_dataset {
    my ( $self, $dataset_hashref ) = @_;
    
    my %dataset = %$dataset_hashref;  
    my $rawdata_ref = delete $dataset{raw_data};
    print Dumper($rawdata_ref);
    my $raw_data = [map {EpiRR::Model::RawData->new(%$_)} @$rawdata_ref];
    $dataset{raw_data} = $raw_data;
    
    return EpiRR::Model::Dataset->new(%dataset);
}



__PACKAGE__->meta->make_immutable;

1;
