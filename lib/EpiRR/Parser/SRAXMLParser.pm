package EpiRR::Parser::SRAXMLParser;

use strict;
use warnings;
use Carp;
use feature qw(switch);

use Moose;
use XML::Twig;

with 'EpiRR::Parser::HasErrors';
has 'xml' => ( is => 'ro', isa => 'Str', required => 1 );

sub parse_experiment {
    my ($self) = @_;

    my $e = EpiRR::Model::RawData->new();

    my $t = XML::Twig->new(
        twig_handlers => {
            'EXPERIMENT' => sub {
                my ( $t, $element ) = @_;
                my $id = $element->{'att'}->{'accession'};
                $self->push_error("Cannot handle multiple experiments")
                  if $e->primary_id();
                $e->primary_id($id);

            },
            'SAMPLE_DESCRIPTOR' => sub {
                my ( $t, $element ) = @_;
                my $sample = $element->{'att'}->{'accession'};
                $self->push_error("Cannot handle multiple samples")
                  if $e->secondary_id();
                $e->secondary_id($sample);
            },
            'EXPERIMENT_ATTRIBUTE' => sub {
                my ( $t, $element ) = @_;

                if ( $element->first_child_text('TAG') eq 'EXPERIMENT_TYPE' ) {
                    my $experiment_type = $element->first_child_text('VALUE');
                    $self->push_error("Cannot handle multiple experiment_types")
                      if $e->experiment_type();

                    $e->experiment_type($experiment_type);
                }
            },
        }
    );
    $t->parse( $self->xml() );
    
    $self->push_error("Experiment ID not found in XML") unless $e->primary_id();
    $self->push_error("Sample ID not found in XML") unless $e->secondary_id();
    $self->push_error("Experiment type not found in XML") unless $e->experiment_type();
    
    return $e;
}

__PACKAGE__->meta->make_immutable;
1;
