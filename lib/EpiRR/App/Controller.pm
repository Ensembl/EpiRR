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
package EpiRR::App::Controller;

use Moose;
use Carp;
use EpiRR::Parser::JsonParser;
has 'conversion_service' => (
    is       => 'rw',
    isa      => 'EpiRR::Service::ConversionService',
    required => 1,
);
has 'json_parser' => (
    is       => 'rw',
    isa      => 'EpiRR::Parser::JsonParser',
    required => 1,
    default  => sub {
        EpiRR::Parser::JsonParser->new();
    },
);
has 'schema' => ( is => 'rw', isa => 'EpiRR::Schema', required => 1 );

sub fetch_current {
    my ($self) = @_;



    my $cs                = $self->conversion_service();
    my @current_data_sets = $self->schema()->dataset_version()->search(
        { is_current => 1 },
        {
            prefetch => {
                dataset => ['project'],
                type    => [],
                status  => [],
                raw_datas => ['archive'],
                meta_datas => [],
            },
            collapse => 1,
        }
    );
    my @dsv = map { $cs->db_to_user($_) } @current_data_sets;
    return \@dsv;
}

sub fetch_decorated_current {
    my ($self) = @_;

    my $datasets = $self->fetch_current();

    my @d_datasets = map { _decorate($_) } @$datasets;

    return \@d_datasets;
}

sub _decorate {
    my ($dataset) = @_;
    my $decorated = $dataset->to_hash();

    delete $decorated->{meta_data};
    delete $decorated->{raw_data};

    my @desc_keys = qw(
      disease   biomaterial_type line
      donor_id  pool_id
      cell_type tissue_type
    );
    my @tags =
      grep { $_ && lc($_) ne 'na' && lc($_) ne 'none' }
      $dataset->get_meta_data(@desc_keys);

    $decorated->{auto_desc} = join( ',', @tags );

    for my $kv ( $dataset->meta_data_kv() ) {
        my $k = 'md_' . $kv->[0];
        $decorated->{$k} = $kv->[1];
    }

    for my $rd ( $dataset->all_raw_data ) {
        my $url_key;

        if ( $rd->data_type eq 'ChIP-Seq' ) {
            $url_key = $rd->experiment_type();
            $url_key =~ s/histone //i;
        }
        else {
            $url_key = $rd->data_type();
        }

        $url_key = lc($url_key);

        $url_key =~ tr/ -/__/;

        $decorated->{urls}{$url_key} = $rd->archive_url();
    }

    return $decorated;
}

sub fetch {
    my ( $self, $id ) = @_;

    my $data_set_version =
      $self->schema->dataset()->find( { accession => $id, } )
      ->search_related( 'dataset_versions', { is_current => 1 } )->first();

    if ( !$data_set_version ) {
        $data_set_version =
          $self->schema->dataset_version()->find( { full_accession => $id } );
    }

    if ($data_set_version) {
        return $self->conversion_service()->db_to_user($data_set_version);
    }
    else {
        return;
    }
}

sub submit {
    my ( $self, $project, $json ) = @_;

    my $errors = [];

    my $user_datasets = $self->json_parser()->parse( $json, $errors );

    if ( !$user_datasets ) {
        push @$errors, 'No dataset decoded';
    }
    if ( scalar(@$user_datasets) ) {
        push @$errors, 'Multiple datasets submitted';
    }

    if ( !@$errors ) {
        my $dataset =
          $self->conversion_service()
          ->user_to_db( $user_datasets->[0], $errors );
        if (@$errors) {
            return ( '', $errors );
        }
        else {
            return ( $dataset->accession, $errors );
        }
    }
}

1;
