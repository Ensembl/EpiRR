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
use Data::Dumper;
use namespace::autoclean;

use EpiRR::Model::Dataset;
use EpiRR::Model::RawData;

use Moose;
use JSON;
use Carp;
use Try::Tiny;
with 'EpiRR::Roles::InputParser';

=head1 NAME

EpiRR::Parser::JSONParser

Parses JSON to produce EpiRR::Model::Dataset objects.
Input JSON:
{"project": "ENCODE",
  "local_name": "ENCSR888PLC",
  "description": "Reference epigenome of Karpas-422",
  "raw_data": [
      {"archive": "GEO", "primary_id": "GSM2072529"},
      {"archive": "GEO", "primary_id": "GSM2072530"},
      {"archive": "GEO", "primary_id": "GSM2071622"},
      {"archive": "GEO", "primary_id": "GSM2071623"}
  ]}

=cut

sub parse {
    my ($self) = @_;

    my ( $json, $perl_data );
    try {
        $json = $self->_get_string();
    }
    catch {
        $self->add_error("Could not get JSON");
    };
    try {
        $perl_data = decode_json($json) if ($json);
    }
    catch {
        $self->add_error("Not a valid JSON file");
    };
    $self->convert_dataset($perl_data) if ($perl_data);
}

sub _get_string {
    my ($self) = @_;

    my $string = $self->string();

    if ( !$string ) {
        local $/ = undef;
        $self->_open();
        my $fh = $self->file_handle();
        $string = <$fh>;
        $self->_close();
    }

    return $string;

}
# $dataset_hashref:
# 'accession' => 'IHECRE00003843',
# 'description' => 'Sample AML_230-60/CEMT0172',
# 'local_name' => 'CEMT0172',
# 'project' => 'CEEHRC',
# 'raw_data' => [...]
#
# $rawdata_ref:
# {'archive' => 'EGA',
# 'primary_id' => 'EGAX00001645025',
# 'secondary_id' => 'EGAD00001003963'}
#
# $raw_data
# {'archive' => 'EGA',
#  'meta_data' => {},
#  'primary_id' => 'EGAX00001645061',
#  'secondary_id' => 'EGAD00001003963'
#  }, 'EpiRR::Model::RawData'}
sub convert_dataset {
    my ( $self, $dataset_hashref ) = @_;

    my %dataset = %$dataset_hashref;
    # returns deleted data
    my $rawdata_ref = delete $dataset{raw_data};
    # Create RawData from JSON
    my $raw_data = [ map { EpiRR::Model::RawData->new(%$_) } @$rawdata_ref ];

    my %rd_ids;
    # Check for duplicates in JSON file by creating a unique key
    for my $rd (@$raw_data){
      my $key = join(';',grep {defined $_} $rd->archive,$rd->primary_id,$rd->secondary_id);
      $rd_ids{$key}++;
      if ($rd_ids{$key} > 1){

        $self->add_error('Duplicate raw_data values detected: '.$key);
      }
    }

    $dataset{raw_data} = $raw_data;

    $self->dataset( EpiRR::Model::Dataset->new(%dataset) );
}

__PACKAGE__->meta->make_immutable;

1;
