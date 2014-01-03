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
package EpiRR::Service::ArrayExpress;

use Moose;
use namespace::autoclean;
use LWP;
use Carp;
use URI::Encode qw(uri_encode);
use BioSD;
use JSON;

with 'EpiRR::Roles::ArchiveAccessor', 'EpiRR::Roles::HasUserAgent';

has '+supported_archives' => ( default => sub { ['AE'] }, );

sub lookup_raw_data {
    my ( $self, $raw_data, $errors ) = @_;

    confess("Must have raw data") if ( !$raw_data );
    confess("Raw data must be EpiRR::Model::RawData")
      if ( !$raw_data->isa('EpiRR::Model::RawData') );
    confess( "Cannot handle this archive: " . $raw_data->archive() )
      if ( !$self->handles_archive( $raw_data->archive() ) );

    my $experiment =
      $self->lookup_experiment( $raw_data->primary_id(), $errors );

    $experiment->archive_url(
        $self->get_url( $experiment->primary_id(), $raw_data->secondary_id() )
    );

    my $sample = $self->lookup_sample( $experiment->primary_id(),
        $raw_data->secondary_id() );

    return ( $experiment, $sample );
}

sub get_url {
    my ( $self, $experiment_id, $sample_name ) = @_;

    my $e = uri_encode($experiment_id);
    my $s = uri_encode($sample_name);

    return "http://www.ebi.ac.uk/arrayexpress/experiments/$e/samples/$s";
}

sub lookup_experiment {
    my ( $self, $id, $errors ) = @_;

    confess("ID is required") unless $id;

    my $encoded_id = uri_encode($id);

    my $url =
      'http://www.ebi.ac.uk/arrayexpress/json/v2/experiments/' . $encoded_id;
    my $req = HTTP::Request->new( GET => $url );

    my $res = $self->user_agent->request($req);
    my $json;

    # Check the outcome of the response
    if ( $res->is_success ) {
        $json = $res->content;
    }
    else {
        confess( "Error requesting $url:" . $res->status_line );
    }

    my $data = decode_json $json;

    my $total_experiments = $data->{experiments}->{total} || 0;
    if ( $total_experiments != 1 ) {
        push @$errors,
"ArrayExpress returned $total_experiments experiments, must have 1 to process";
        return undef;
    }

    my $experiment_type = $data->{experiments}->{experiment}->{experimenttype};
    my $experiment_id   = $data->{experiments}->{experiment}->{accession};

    my $raw_data = EpiRR::Model::RawData->new(
        archive         => 'AE',
        primary_id      => $experiment_id,
        experiment_type => $experiment_type,
    );

    return ($raw_data);
}

sub lookup_sample {
    my ( $self, $experiment_id, $sample_name, $errors ) = @_;

    my $groups = BioSD::search_for_groups($experiment_id);
    if ( !@$groups ) {
        push @$errors, "No BioSamples group found for $experiment_id";
        return undef;
    }
    
    my @samples;
    for my $g (@$groups) {
        my $s = $g->search_for_samples($sample_name);
        push @samples, @$s;
    }

    if ( !@samples ) {
        push @$errors,
          "No BioSamples records found for $experiment_id, $sample_name";
        return undef;
    }
    if (scalar(@samples) > 1) {
      push @$errors, "More than one BioSamples record found for $experiment_id, $sample_name";
    }
    
    my $s = pop @samples;
    my $sample = EpiRR::Model::Sample->new(
        sample_id => $s->id(),
    );
    
    for my $p (@{$s->properties}) {
      $sample->set_meta_data($p->class(), join(', ',@{$p->values()}));
    }
    
    return $sample;

}
__PACKAGE__->meta->make_immutable;
1;
