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
use EpiRR::Parser::SRAXMLParser;
use EpiRR::Types;
use XML::Twig;

with 'EpiRR::Roles::ArchiveAccessor', 'EpiRR::Roles::HasUserAgent';

has '+supported_archives' => ( default => sub { ['GEO'] }, );
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
has 'sra_xml_parser' => (
    is       => 'rw',
    isa      => 'EpiRR::Parser::SRAXMLParser',
    required => 1,
    default  => sub { EpiRR::Parser::SRAXMLParser->new() },
    lazy     => 1
);
has 'base_url' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default  => 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/'
);
has 'archive_link_url' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
    default  => 'http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc='
);

sub lookup_raw_data {
    my ( $self, $raw_data, $errors ) = @_;

    confess("Must have raw data") if ( !$raw_data );
    confess("Raw data must be EpiRR::Model::RawData")
      if ( !$raw_data->isa('EpiRR::Model::RawData') );
    confess( "Cannot handle this archive: " . $raw_data->archive() )
      if ( !$self->handles_archive( $raw_data->archive() ) );

    my $accession = $raw_data->primary_id();

    my $uids        = $self->_accession_to_uids($accession);
    my $sample_uids = $self->_find_sample_uid($uids);
    my $sra_uids    = $self->_find_sra_uids($sample_uids);
    my ( $experiment_type, $sample ) =
      $self->_get_sra_sample_and_experiment(@$sra_uids);

    my $archive_url = $self->archive_link_url() . uri_encode($accession);

    #TODO error handling??
    my $raw_data_out = EpiRR::Model::RawData->new(
        archive         => 'GEO',
        primary_id      => $accession,
        experiment_type => $experiment_type,
        archive_url     => $archive_url,
    );

    return ( $raw_data_out, $sample );
}

sub _accession_to_uids {
    my ( $self, $accession ) = @_;

    my $url =
        $self->base_url()
      . 'esearch.fcgi?db=gds&field=ACCN&term='
      . uri_encode($accession);
    my $xml = $self->_make_eutils_request($url);

#example http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=gds&term=GSM409307&field=ACCN
    my @uids;
    my $t = XML::Twig->new(
        twig_handlers => {
            'IdList/Id' => sub {
                my ( $t, $element ) = @_;
                push @uids, $element->text();
              }
        }
    );
    $t->parse($xml);
    return \@uids;
}

sub _find_sample_uid {
    my ( $self, $uids ) = @_;

#example http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=gds&id=200016256,100009115,300409307
    my $url =
        $self->base_url()
      . 'esummary.fcgi?db=gds&id='
      . uri_encode( join( ',', @$uids ) );
    my $xml = $self->_make_eutils_request($url);

    my @sample_uids;

    my $t = XML::Twig->new(
        twig_handlers => {
            "Item[\@Name='entryType']" => sub {
                my ( $t, $element ) = @_;

                if ( $element->text() eq 'GSM' ) {
                    my $id_element = $element->prev_sibling('Id')
                      || $element->next_sibling('Id');
                    confess("No id element found in XML for $url")
                      unless $id_element;
                    my $id = $id_element->text();
                    push @sample_uids, $id;
                }
              }
        }
    );
    $t->parse($xml);
    return \@sample_uids;
}

sub _find_sra_uids {
    my ( $self, $uids ) = @_;

#example http://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi?db=sra&dbfrom=gds&id=300409307
    my $url =
        $self->base_url()
      . 'elink.fcgi?db=sra&dbfrom=gds&id='
      . uri_encode( join( ',', @$uids ) );
    my $xml = $self->_make_eutils_request($url);

    my @sra_uids;

    my $t = XML::Twig->new(
        twig_handlers => {
            'Link/Id' => sub {
                my ( $t, $element ) = @_;
                push @sra_uids, $element->text();
              }
        }
    );
    $t->parse($xml);
    return \@sra_uids;
}

sub _get_sra_sample_and_experiment {
    my ( $self, $uid, $errors ) = @_;

#example http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=sra&id=6495

    my $url = $self->base_url() . 'efetch.fcgi?db=sra&id=' . uri_encode($uid);
    my $xml = $self->_make_eutils_request($url);

    my ( $sample_id, $experiment_type, $experiment_id ) =
      $self->sra_xml_parser()->parse_experiment( $xml, $errors );
    my $sample = $self->sra_xml_parser()->parse_sample( $xml, $errors );

    return ( $experiment_type, $sample );
}

sub _make_eutils_request {
    my ( $self, $url ) = @_;

    my $req = HTTP::Request->new( GET => $url );

    $self->throttler()->do_action();
    my $res = $self->user_agent->request($req);
    my $resp;

    # Check the outcome of the response
    if ( $res->is_success ) {
        $resp = $res->content;
    }
    else {
        confess( "Error requesting $url:" . $res->status_line );
    }

    return $resp;
}

__PACKAGE__->meta->make_immutable;
1;
