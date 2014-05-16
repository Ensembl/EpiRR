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
package EpiRR::Service::EGAInternal;

use Moose;
use namespace::autoclean;
use Carp;
use URI::Encode qw(uri_encode);

use XML::Twig;
use LWP;
extends 'EpiRR::Service::ENAInternal';
with 'EpiRR::Roles::HasUserAgent';

has '+supported_archives' => ( default => sub { ['EGA'] }, );
has '+experiment_sql' => ( default =>
'select ega_id, status_id, xmltype.getclobval(experiment_xml) from experiment where ? in (experiment_id, ega_id) and ega_id is not null'
);
has '+base_url'        => ( default => 'https://www.ebi.ac.uk/ega/datasets/' );
has '+valid_status_id' => ( default => 2 );
has '+sample_sql' => ( default =>
'select sample_id, xmltype.getclobval(sample_xml) from sample where sample_id = ?'
);

sub get_url {
    my ( $self, $experiment_id, $secondary_id, $errors ) = @_;

    my $sql = <<END;
SELECT count(EGA_DATASET.EGA_DATASET_ID)
FROM EXPERIMENT
JOIN RUN ON EXPERIMENT.EXPERIMENT_ID = RUN.EXPERIMENT_ID
JOIN RUN_EGA_DATASET ON RUN.RUN_ID = RUN_EGA_DATASET.RUN_ID
JOIN EGA_DATASET ON RUN_EGA_DATASET.EGA_DATASET_ID = EGA_DATASET.EGA_DATASET_ID
WHERE EXPERIMENT.EGA_ID = ?
  AND EGA_DATASET.EGA_DATASET_ID = ?
END

    my $stmt = $self->database_handle()->prepare( $self->experiment_sql() );
    my $count =
      $self->database_handle()
      ->selectrow_array( $sql, undef, $experiment_id, $secondary_id );

    if ( $count < 1 ) {
        push @$errors, "Did not find experiment in dataset";
        return undef;
    }

    my $url = $self->base_url() . $secondary_id;
    my $req = HTTP::Request->new( GET => $url );

    my $res = $self->user_agent->request($req);

    # Check the outcome of the response
    if ( $res->is_success ) {
        my $html = $res->content;
        my $title;

        if ( $html =~ /This dataset is featured in/ ) {
            return $url;
        }
        else {
            push @$errors,
              "Could not confirm that EGA dataset $secondary_id is available";
            return;
        }
    }
    else {
        confess( "Error requesting $url:" . $res->status_line );
    }
}

__PACKAGE__->meta->make_immutable;
1;
