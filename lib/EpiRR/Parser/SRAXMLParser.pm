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
package EpiRR::Parser::SRAXMLParser;

use strict;
use warnings;
use Carp;
use feature qw(switch say);
use Data::Dumper;
use Moose;
use namespace::autoclean;
use XML::Twig;
use EpiRR::Model::Experiment;
use EpiRR::Model::Sample;
use EpiRR::Model::RawData;


sub parse_experiment {
    my ( $self, $xml, $errors ) = @_;
    my $experiment = EpiRR::Model::Experiment->new();
    my $experiment_type_cache;
    my $library_strategy_cache;
 
    my $t = XML::Twig->new(
        twig_handlers => {
            'EXPERIMENT' => sub {
                my ( $t, $element ) = @_;
                my $id = $element->{'att'}->{'accession'};
                    push @$errors, "Cannot handle multiple experiments in XML" 
                    if (defined $experiment->experiment_id());
                $experiment->experiment_id($id);
            },
            'LIBRARY_STRATEGY' => sub {
                my ( $t, $element ) = @_;
                $library_strategy_cache = $element->trimmed_text();
                $experiment->set_meta_data( 'library_strategy', $library_strategy_cache );
            },
            'SAMPLE_DESCRIPTOR' => sub {
                my ( $t, $element ) = @_;
                my $sample = $element->{'att'}->{'accession'};
                    push @$errors, "Found multiple samples in XML" 
                    if (defined $experiment->sample_id());
                $experiment->sample_id($sample);
            },
            'EXPERIMENT_ATTRIBUTE' => sub {
                my ( $t, $element ) = @_;
 
                if ( $element->first_child_text('TAG') eq 'EXPERIMENT_TYPE' ) {
                    my $experiment_type = $element->first_child_text('VALUE');
                        push @$errors, "Found multiple experiment types in XML" 
                        if (defined $experiment_type_cache);
                    $experiment_type_cache = $experiment_type;
                }
                $experiment->set_meta_data( $element->first_child_text('TAG'), $element->first_child_text('VALUE') );
            },
        }
    );
    $t->parse($xml);
        push @$errors, "No experiment found" unless $experiment->experiment_id();
        if ($experiment->experiment_id()){
            push @$errors, "No experiment_type found" unless defined $experiment_type_cache;
            push @$errors, "No sample found" unless defined $experiment->sample_id();
            push @$errors, "No library_strategy found" unless $library_strategy_cache;
        }

    return ($experiment);
}

sub parse_sample {
    my ( $self, $xml, $errors ) = @_;
    my $s = EpiRR::Model::Sample->new();

    my $t = XML::Twig->new(
        twig_handlers => {
            'SAMPLE' => sub {
                my ( $t, $element ) = @_;
                my $id = $element->{'att'}->{'accession'};
                    push @$errors, "Cannot handle multiple samples"
                    if ( $s->sample_id() );
                $s->sample_id($id);
            },
            'SAMPLE_ATTRIBUTE' => sub {
                my ( $t, $element ) = @_;

                my $tag   = ( $element->first_child_text('TAG') );
                my $value = $element->first_child_text('VALUE');
                $s->set_meta_data( $tag, $value );
            },
            'SCIENTIFIC_NAME' => sub {
                my ( $t, $element ) = @_;

                my $value = $element->text();
                $s->set_meta_data( 'species', $value );
              },
              'TAXON_ID' => sub {
                my ( $t, $element ) = @_;

                my $value = $element->text();
                $s->set_meta_data( 'taxon_id', $value );
              }
        }
    );
    $t->parse($xml);
        push @$errors, "Sample ID not found in XML" if ( !$s->sample_id() );
    return $s;
}

__PACKAGE__->meta->make_immutable;
1;
