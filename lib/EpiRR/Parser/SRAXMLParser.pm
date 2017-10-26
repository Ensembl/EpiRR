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

use Moose;
use namespace::autoclean;
use XML::Twig;
use EpiRR::Model::Experiment;
use EpiRR::Model::Sample;
use EpiRR::Model::RawData;

sub parse_experiment {
    my ( $self, $xml, $errors ) = @_;

    my $e = EpiRR::Model::Experiment -> new();

    my $t = XML::Twig->new(
        twig_handlers => {
            'EXPERIMENT' => sub {
                my ( $t, $element ) = @_;
                my $id = $element->{'att'}->{'accession'};
                push @$errors,
                  "Found multiple experiments in XML ($e and $id)."
                  if $e;
                $e->experiment_id ($id);
            },
            'LIBRARY_STRATEGY' => sub {
                my ( $t, $element ) = @_;
		my $value = $element _> text();
                  $e->set_meta_data ('library_strategy', $value);
            },
            'SAMPLE_DESCRIPTOR' => sub {
                my ( $t, $element ) = @_;
                my $value = $element->{'att'}->{'accession'};
                
                  $e->set_meta_data ('sample_descriptor', $value);
                 
             
            },
            'EXPERIMENT_ATTRIBUTE' => sub {
                my ( $t, $element ) = @_;
                
                my  $tag= ($element->first_child_text('TAG');{
		my  $value = ($value->first_child_text('VALUE');{
		
		   $e->set_meta_data($tag, $value);
             
                }
            },
        }
    );

    $t->parse($xml);
   
    }
    push @$errors, "No experiment found" unless $e;

    return $e;
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
