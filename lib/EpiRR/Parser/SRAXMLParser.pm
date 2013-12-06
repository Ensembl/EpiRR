package EpiRR::Parser::SRAXMLParser;

use strict;
use warnings;
use Carp;
use feature qw(switch);

use Moose;
use namespace::autoclean;
use XML::Twig;

sub parse_experiment {
    my ($self, $xml, $errors) = @_;

    my ( $e_id, $s_id, $et );

    my $t = XML::Twig->new(
        twig_handlers => {
            'EXPERIMENT' => sub {
                my ( $t, $element ) = @_;
                my $id = $element->{'att'}->{'accession'};
                push @$errors, "Found multiple experiments in XML ($e_id and $id)."
                  if $e_id;
                $e_id = $id;
            },
            'SAMPLE_DESCRIPTOR' => sub {
                my ( $t, $element ) = @_;
                my $sample = $element->{'att'}->{'accession'};
                push @$errors, "Found multiple samples in XML ($s_id and $sample)" if ($s_id);
                $s_id = $sample;
            },
            'EXPERIMENT_ATTRIBUTE' => sub {
                my ( $t, $element ) = @_;

                if ( $element->first_child_text('TAG') eq 'EXPERIMENT_TYPE' ) {
                    my $experiment_type = $element->first_child_text('VALUE');
                    push @$errors, "Found multiple experiment types in XML ($et and $experiment_type)" if ($et);

                    $et = $experiment_type;
                }
            },
        }
    );
    $t->parse( $xml );
    push @$errors, "No experiment found" unless $e_id;
    push @$errors, "No experiment_type found" unless $et;
    push @$errors, "No sample found" unless $s_id;
    return ($s_id,$et,$e_id);
}

sub parse_sample {
    my ($self,$xml,$errors) = @_;

    my $s = EpiRR::Model::Sample->new();

    my $t = XML::Twig->new(
        twig_handlers => {
            'SAMPLE' => sub {
                my ( $t, $element ) = @_;
                my $id = $element->{'att'}->{'accession'};
                push @$errors, "Cannot handle multiple samples"                 if ($s->sample_id());
                $s->sample_id($id);
            },
            'SAMPLE_ATTRIBUTE' => sub {
                my ( $t, $element ) = @_;

                my $tag   = $element->first_child_text('TAG');
                my $value = $element->first_child_text('VALUE');

                $s->set_meta_data( $tag, $value );
            },
            'SCIENTIFIC_NAME' => sub {
                my ( $t, $element ) = @_;

                my $value = $element->text();
                $s->set_meta_data( 'SPECIES', $value );
              }
        }
    );
    $t->parse( $xml );

    push @$errors, "Sample ID not found in XML" if (!$s->sample_id());

    return $s;
}

__PACKAGE__->meta->make_immutable;
1;
