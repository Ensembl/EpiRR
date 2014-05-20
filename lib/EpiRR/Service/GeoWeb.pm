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
package EpiRR::Service::GeoWeb;

use Moose;
use namespace::autoclean;
use LWP;
use Carp;
use URI::Encode qw(uri_encode);
use EpiRR::Service::RateThrottler;
use EpiRR::Parser::GeoMinimlParser;
use EpiRR::Types;

with 'EpiRR::Roles::ArchiveAccessor', 'EpiRR::Roles::HasUserAgent';

has '+supported_archives' => ( default => sub { ['GEO'] }, );

has 'geo_xml_parser' => (
    is       => 'rw',
    isa      => 'EpiRR::Parser::GeoMinimlParser',
    required => 1,
    default  => sub {
        EpiRR::Parser::GeoMinimlParser->new();
    }
);
has 'base_xml_url' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default =>
'http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?targ=self&form=xml&view=quick&acc='
);
has 'archive_link_url' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default  => 'http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc='
);

sub lookup_raw_data {
    my ( $self, $raw_data, $errors ) = @_;

    $errors = [] unless $errors;

    confess("Must have raw data") if ( !$raw_data );
    confess("Raw data must be EpiRR::Model::RawData")
      if ( !$raw_data->isa('EpiRR::Model::RawData') );
    confess( "Cannot handle this archive: " . $raw_data->archive() )
      if ( !$self->handles_archive( $raw_data->archive() ) );

    my $accession = $raw_data->primary_id();

    my ( $raw_data_out, $sample );
    my $experiment_type;
    ( $experiment_type, $sample ) = $self->_geo_miniml( $accession, $errors );

    if ( !@$errors ) {
        $raw_data_out =
          EpiRR::Model::RawData->new( experiment_type => $experiment_type );

        my $archive_url = $self->archive_link_url() . uri_encode($accession);
        $raw_data_out->archive_url($archive_url);
        $raw_data_out->archive('GEO');
        $raw_data_out->primary_id($accession);
    }
    return ( $raw_data_out, $sample );

}

sub _geo_miniml {
    my ( $self, $accession, $errors ) = @_;

    my $main_xml = $self->_get_xml($accession);

    if ( $main_xml =~ m/\<!DOCTYPE HTML/ ) {
        push @$errors, "Geo returned no data for $accession";
        return;
    }

    my ( $platform_id, $sample, $experiment_type ) =
      $self->geo_xml_parser()->parse_main( $main_xml, $errors );

    if ( !$experiment_type ) {
        my $platform_xml = $self->_get_xml($platform_id);
        $experiment_type =
          $self->geo_xml_parser()->parse_platform( $platform_xml, $errors );
    }

    return ( $experiment_type, $sample );
}

sub _get_xml {
    my ( $self, $accession ) = @_;

    confess("accession is required") unless $accession;

    my $url = $self->base_xml_url() . uri_encode($accession);

    my $req = HTTP::Request->new( GET => $url );
    my $res = $self->user_agent->request($req);
    my $xml;

    # Check the outcome of the response
    if ( $res->is_success ) {
        $xml = $res->content;
    }
    else {
        confess( "Error requesting $url:" . $res->status_line );
    }
    return $xml;
}

__PACKAGE__->meta->make_immutable;
1;
