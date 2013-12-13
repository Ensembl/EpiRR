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
package EpiRR::Service::ENAInternal;

use Moose;
use namespace::autoclean;
use Carp;
use URI::Encode qw(uri_encode);

use EpiRR::Parser::SRAXMLParser;

with 'EpiRR::Roles::ArchiveAccessor';

has '+supported_archives' => ( default => sub { [ 'ENA', 'SRA', 'DDBJ' ] }, );
has 'experiment_sql' => (
    is  => 'rw',
    isa => 'Str',
    default =>
'select experiment_id, status_id, xmltype.getclobval(experiment_xml) from experiment where experiment_id = ? and ega_id is null'
);
has 'sample_sql' => (
    is  => 'rw',
    isa => 'Str',
    default =>
'select sample_id, xmltype.getclobval(sample_xml) from sample where sample_id = ? and ega_id is null'
);
has 'valid_status_id' => ( is => 'rw', isa => 'Int', default => 4 );

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
has 'database_handle' => ( is => 'rw', required => 1, isa => 'DBI::db' );

sub lookup_raw_data {
    my ( $self, $raw_data, $errors ) = @_;

    confess("Must have raw data") if ( !$raw_data );
    confess("Raw data must be EpiRR::Model::RawData")
      if ( !$raw_data->isa('EpiRR::Model::RawData') );
    confess( "Cannot handle this archive: " . $raw_data->archive() )
      if ( !$self->handles_archive( $raw_data->archive() ) );

    my ( $experiment_id, $experiment_type, $sample_id ) =
      $self->experiment_xml( $raw_data->primary_id(), $errors );
      
    my $sample = $self->lookup_sample( $sample_id, $errors ) if ($sample_id);

    my $archive_raw_data = EpiRR::Model::RawData->new(
        primary_id      => $experiment_id,
        experiment_type => $experiment_type,
        archive         => $raw_data->archive(),
        archive_url =>
          $self->get_url( $experiment_id, $raw_data->secondary_id(), $errors ),
    );
    use Data::Dumper;print Dumper([$experiment_id, $experiment_type, $sample_id,$archive_raw_data,$sample] );
    return ( $archive_raw_data, $sample );
}

sub get_url {
    my ( $self, $experiment_id, $secondary_id, $errors ) = @_;

    return $self->base_url() . $experiment_id;
}

sub experiment_xml {
    my ( $self, $experiment_id, $errors ) = @_;

    my $stmt = $self->database_handle()->prepare( $self->experiment_sql() );
    $stmt->bind_param( 1, $experiment_id );
    $stmt->execute();

    my $row_array_ref = $stmt->fetchall_arrayref;
    my $nrows         = scalar(@$row_array_ref);

    if ( $nrows != 1 ) {
        push @$errors, "Found $nrows experiments for $experiment_id";
        return undef;
    }

    my $row = pop @$row_array_ref;
    my ( $id, $status_id, $xml ) = @$row;

    push @$errors, "Experiment does not have a valid status"
      if ( $status_id != $self->valid_status_id() );

    my ( $s_id, $et, $e_id ) = $self->xml_parser()->parse_experiment($xml);

    return ( $id, $et, $s_id );
}

sub lookup_sample {
    my ( $self, $sample_id, $errors ) = @_;
    confess("Sample ID is required") unless $sample_id;

    my $stmt = $self->database_handle()->prepare( $self->sample_sql() );
    $stmt->bind_param( 1, $sample_id );
    $stmt->execute();

    my $row_array_ref = $stmt->fetchall_arrayref;
    my $nrows         = scalar(@$row_array_ref);

    if ( $nrows != 1 ) {
        push @$errors, "Found $nrows samples for $sample_id";
        return undef;
    }

    my $row = pop @$row_array_ref;
    my ( $id, $xml ) = @$row;

    my $sample = $self->xml_parser()->parse_sample( $xml, $errors );

    return $sample;
}

__PACKAGE__->meta->make_immutable;
1;
