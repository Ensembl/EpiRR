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
package EpiRR::Service::GeoEutils;

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
has 'eutils' => (
    is       => 'rw',
    isa      => 'EpiRR::Service::NcbiEutils',
    required => 1,
);
has 'sra_accessor' => (
    is       => 'rw',
    isa      => 'ArchiveAccessor',
    required => 1,
);

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
has 'throttler' => (
    is       => 'ro',
    isa      => 'Throttler',
    required => 1,
    default  => sub {
        EpiRR::Service::RateThrottler->new(
            actions_permitted_per_period => 3,
            sampling_period_seconds      => 1,
        );
    }
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

    my $gsm_uids = $self->_esearch_geo($accession);

    push @$errors, "No UIDs found for accession $accession" unless @$gsm_uids;

    my ($sra_accessions) = $self->_esummary_geo($gsm_uids);

    push @$errors, "No GEO sample UIDs found for accession $accession"
      unless @$gsm_uids;
    push @$errors, "Found multiple GEO sample UIDs for accession $accession"
      if ( $gsm_uids && scalar(@$gsm_uids) > 1 );
    push @$errors, "Found multiple SRA accessions for $accession"
      if ( $sra_accessions && scalar(@$sra_accessions) > 1 );

    return if @$errors;
    my ( $raw_data_out, $sample );

    if (@$sra_accessions) {
        my $sra_raw_data = EpiRR::Model::RawData->new(
            archive    => 'SRA',
            primary_id => $sra_accessions->[0],
        );

        ( $raw_data_out, $sample ) =
          $self->sra_accessor->lookup_raw_data( $sra_raw_data, $errors );

    }
    else {
        my $experiment_type;
        ( $experiment_type, $sample ) = $self->_geo_miniml($accession);
        $raw_data_out =
          EpiRR::Model::RawData->new( experiment_type => $experiment_type );
    }

    my $archive_url = $self->archive_link_url() . uri_encode($accession);
    $raw_data_out->archive_url($archive_url);
    $raw_data_out->archive('GEO');
    $raw_data_out->primary_id($accession);

    return ( $raw_data_out, $sample );

}

sub _geo_miniml {
    my ( $self, $accession, $errors ) = @_;

    my $main_xml = $self->_get_xml($accession);

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
    $self->throttler()->do_action();
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

sub _esearch_geo {
    my ( $self, $accession ) = @_;
    my @uids =
      $self->eutils->esearch( "${accession}[ACCN] AND GSM[ETYP]", 'gds' );
    return \@uids;
}

sub _docSum_external_relations_hash {
    my ( $self, $docSum ) = @_;

    my ($list) = $docSum->get_Items_by_name('ExtRelations');

    my %ext_relations;
    if ($list) {
        while ( my $relation = $list->next_Item() ) {
            my ($type)   = $relation->get_contents_by_name('RelationType');
            my ($target) = $relation->get_contents_by_name('TargetObject');

            $ext_relations{$type} = $target;
        }
    }

    return %ext_relations;
}

sub _esummary_geo {
    my ( $self, $uids ) = @_;

    my @sample_uids;
    my @sra_accessions;
    my @docSums = $self->eutils->esummary( $uids, 'gds' );

    for my $docSum (@docSums) {
        my ($entryType) = $docSum->get_contents_by_name('entryType');
        next if ( $entryType ne 'GSM' );

        my %ext_relations = $self->_docSum_external_relations_hash($docSum);
        my $sra_accession = $ext_relations{SRA} || $ext_relations{sra};
        if ($sra_accession) {
            push @sra_accessions, $sra_accession;
        }
    }
    return \@sra_accessions;
}

__PACKAGE__->meta->make_immutable;
1;
