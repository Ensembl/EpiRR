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
package EpiRR::Parser::GeoMinimlParser;

use strict;
use warnings;
use Carp;
use feature qw(switch);

use Moose;
use namespace::autoclean;
use XML::Twig;

use EpiRR::Model::Sample;
use EpiRR::Model::RawData;

sub parse_main {
    my ( $self, $xml, $errors ) = @_;

    my ( $platform_id, $experiment_type, $library_strategy, $contributor );
    my $s = EpiRR::Model::Sample->new();

    my $t = XML::Twig->new(
        twig_handlers => {
            'Characteristics' => sub {
                my ( $t, $element ) = @_;
                my $tag   = $element->{'att'}->{'tag'};
                my $value = $element->trimmed_text();

                if ( $tag eq 'experiment_type' ) {
                    $experiment_type = $value;
                }
                else {
                    $s->set_meta_data( $tag, $value );
                }
            },
            'Library-Strategy' => sub {
                my ( $t, $element ) = @_;
                $library_strategy = $element->trimmed_text();
            },
            'Sample' => sub {
                my ( $t, $element ) = @_;
                $s->sample_id( $element->{'att'}->{'iid'} );
            },
            'Organism' => sub {
                my ( $t, $element ) = @_;
                my $taxid   = $element->{'att'}->{'taxid'};
                my $species = $element->trimmed_text();

                $s->set_meta_data(
                    'taxon_id' => $taxid,
                    'species'  => $species,
                );
              },
              'Platform' => sub {
                my ( $t, $element ) = @_;
                $platform_id = $element->{'att'}->{'iid'};
              },
              'Contributor/Person/First' => sub {
                my ( $t, $element ) = @_;
                $contributor = $element->trimmed_text();
              }
        }
    );
    if($contributor eq 'ENCODE') {

    }

    $t->parse($xml);
    return ( $platform_id, $s, $experiment_type, $library_strategy );
}

sub parse_platform {
    my ( $self, $xml, $errors ) = @_;

    my $platform;
    my $s = EpiRR::Model::Sample->new();

    my $t = XML::Twig->new(
        twig_handlers => {
            'Platform/Title' => sub {
                my ( $t, $element ) = @_;
                $platform = $element->trimmed_text();
            },
        }
    );
    $t->parse($xml);
    return ($platform);
}

__PACKAGE__->meta->make_immutable;
1;
