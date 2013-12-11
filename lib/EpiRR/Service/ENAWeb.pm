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
package EpiRR::Service::ENAWeb;

use Moose;
use namespace::autoclean;
use LWP;
use Carp;
use URI::Encode qw(uri_encode);

use EpiRR::Parser::SRAXMLParser;

with 'EpiRR::Roles::ArchiveAccessor', 'EpiRR::Roles::HasUserAgent';

has '+supported_archives' => ( default => sub { [ 'ENA', 'SRA', 'DDBJ' ] }, );

has 'xml_parser' => (
    is       => 'rw',
    isa      => 'EpiRR::Parser::SRAXMLParser',
    required => 1,
    default  => sub { EpiRR::Parser::SRAXMLParser->new },
    lazy     => 1
);
has 'base_url' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default  => 'http://www.ebi.ac.uk/ena/data/view/'
);

sub lookup_raw_data {
    my ( $self, $raw_data, $errors ) = @_;

    confess("Must have raw data") if ( !$raw_data );
    confess("Raw data must be EpiRR::Model::RawData")
      if ( !$raw_data->isa('EpiRR::Model::RawData') );
    confess( "Cannot handle this archive: " . $raw_data->archive() )
      if ( !$self->handles_archive( $raw_data->archive() ) );

    my $xml = $self->get_xml( $raw_data->primary_id() );

    my ( $sample_id, $experiment_type, $experiment_id ) =
      $self->xml_parser()->parse_experiment( $xml, $errors );

    my $sample = $self->lookup_sample( $sample_id, $errors ) if ($sample_id);

    my $archive_raw_data = EpiRR::Model::RawData->new(
        archive         => $raw_data->archive,
        primary_id      => $experiment_id,
        experiment_type => $experiment_type,
        archive_url     => $self->base_url() . $experiment_id,
    );

    return ($archive_raw_data,$sample);
}

sub lookup_sample {
    my ( $self, $sample_id, $errors ) = @_;
    confess("Sample ID is required") unless $sample_id;

    my $xml = $self->get_xml($sample_id);
    my $sample = $self->xml_parser()->parse_sample( $xml, $errors );

    return $sample;
}

sub get_xml {
    my ( $self, $id ) = @_;

    confess("ID is required") unless $id;

    my $encoded_id = uri_encode($id);

    my $url = $self->base_url() . $encoded_id . '&display=xml';
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
