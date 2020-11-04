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
package EpiRR::Parser::JGAXMLParser;

use strict;
use warnings;
use Carp;
use feature qw(switch say);

use Moose;
use namespace::autoclean;
use XML::Twig;

use EpiRR::Model::Sample;
use EpiRR::Model::RawData;

use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1; 

sub parse_experiment {
  my ( $self, $xml_file, $errors ) = @_;

  my $id = '';
  my $tmp = {};
  my $cache = {};

  my $t = XML::Twig->new(
    twig_handlers => {
      'EXPERIMENT' => sub {
        my ( $t, $element ) = @_;
        $id = $element->{'att'}->{'accession'};
        $tmp->{primary_id} = $id;
        $cache->{$id} = $tmp;
        $tmp = {};
      },
      'SAMPLE_DESCRIPTOR' => sub {
        my ( $t, $element ) = @_;
        $tmp->{sample_id} = $element->{'att'}->{'accession'};
      },
      'DESIGN/LIBRARY_DESCRIPTOR/LIBRARY_STRATEGY' => sub {
        my ( $t, $element ) = @_;
        $tmp->{library_strategy} = $element->trimmed_text();
      },
      # ToDo:  Check for multiple records
      'EXPERIMENT_ATTRIBUTES/EXPERIMENT_ATTRIBUTE/VALUE' => sub {
        my ( $t, $element ) = @_;
        $tmp->{experiment_type} = $element->trimmed_text();
      },
    }
  );

  $t->parsefile($xml_file);
  return($cache);
}
sub _merge {
  my ($self, $tmp, $cache, $id) = @_;


  foreach my $key (sort keys %{$tmp}){
    confess "Duplication [$id]" if(exists $cache->{$id});
    $cache->{$id}=$tmp->{$key};
  }
}

sub parse_sample {
  my ( $self, $xml_file, $errors  ) = @_;

  confess("No XML file passed")
  if(!$xml_file);
  confess("Can't find XML File [$xml_file]")
  if(! -e $xml_file);

  my $id   = '';
  my $cache = {};
  my $sample =  EpiRR::Model::Sample->new();

  my $t = XML::Twig->new(
    twig_handlers => {
      'SAMPLE' => sub {
        my ( $t, $element ) = @_;
        $id = $element->{'att'}->{'accession'};

        confess ("Duplicated sample [$id] in [$xml_file]")
        if(exists $cache->{$id});

        $sample->sample_id($id);
        $cache->{$id} = $sample;
        $sample = EpiRR::Model::Sample->new();
      },
      'SAMPLE_ATTRIBUTE' => sub {
        my ( $t, $element ) = @_;
        my $tag   = ( $element->first_child_text('TAG') );
        my $value = $element->first_child_text('VALUE');
        #$cache->{$id}->{sample_attribute}->{$tag} = $value;
        $sample->set_meta_data($tag,$value);


      },
      'SCIENTIFIC_NAME' => sub {
        my ( $t, $element ) = @_;
        my $name = $element->trimmed_text();
        confess "Missing Scientific Name [$id]"
          if(!defined $name);
          #$cache->{$id}->{species} = $name;
        $sample->set_meta_data( 'species', $name );
      },
      'TAXON_ID' => sub {
        my ( $t, $element ) = @_;
        my $taxon_id = $element->trimmed_text();
        confess "Missing Scientific Name [$id]"
          if(!defined $taxon_id);
#        $cache->{$id}->{taxon_id} = $taxon_id;
        $sample->set_meta_data( 'taxon_id', $taxon_id );
      }
    }
  );
  $t->parsefile($xml_file);
  return($cache);
}

__PACKAGE__->meta->make_immutable;
1;
