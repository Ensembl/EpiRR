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
package EpiRR::Service::SRAEUtils;

use Moose;
use namespace::autoclean;
use LWP;
use Carp;
use URI::Encode qw(uri_encode);

use EpiRR::Parser::SRAXMLParser;

with 'EpiRR::Roles::ArchiveAccessor', 'EpiRR::Roles::HasUserAgent';

has '+supported_archives' => ( default => sub { [ 'ENA', 'SRA', 'DDBJ' ] }, );

has 'sra_xml_parser' => (
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
    default  => 'http://www.ncbi.nlm.nih.gov/sra/'
);
has 'eutils' => (
    is       => 'rw',
    isa      => 'EpiRR::Service::NcbiEUtils',
    required => 1,
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
      $self->sra_xml_parser()->parse_experiment( $xml, $errors );
    my $sample = $self->sra_xml_parser()->parse_sample( $xml, $errors );

    my $archive_raw_data = EpiRR::Model::RawData->new(
        archive         => $raw_data->archive,
        primary_id      => $experiment_id,
        experiment_type => $experiment_type,
        archive_url     => $self->base_url() . $experiment_id,
    );

    return ( $archive_raw_data, $sample );
}

sub get_xml {
    my ( $self, $id ) = @_;

    confess("ID is required") unless $id;

    my @uids = $self->eutils->esearch( "${id}[ACCN]", 'sra' );

    return $self->eutils->efetch( \@uids, 'sra' )->get_Response()->content();
}
__PACKAGE__->meta->make_immutable;
1;
