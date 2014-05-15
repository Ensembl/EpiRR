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
package EpiRR::Service::NcbiEutils;

use Moose;
use namespace::autoclean;
use Carp;
use URI::Encode qw(uri_encode);
use EpiRR::Types;
use EpiRR::Service::RateThrottler;
use Bio::DB::EUtilities;

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

has 'email' => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

sub esearch {
    my ( $self, $term, $db ) = @_;

    $self->throttler->do_action();
    my $eutil = Bio::DB::EUtilities->new(
        -eutil => 'esearch',
        -term  => $term,
        -db    => $db,
        -email => $self->email
    );
    return $eutil->get_ids();
}

sub efetch {
    my ( $self, $id, $db ) = @_;
    $self->throttler->do_action();
    return Bio::DB::EUtilities->new(
        -eutil => 'efetch',
        -id    => $id,
        -db    => $db,
        -email => $self->email
    );
}

sub esummary {
    my ( $self, $ids, $db ) = @_;

    $self->throttler->do_action();
    my $eutil = Bio::DB::EUtilities->new(
        -eutil => 'esummary',
        -id    => $ids,
        -db    => $db,
        -email => $self->email
    );
    return $eutil->get_DocSums();
}

sub elinks {
    my ( $self, $ids, $src_db, $target_db ) = @_;

    $self->throttler->do_action();
    my $eutil = Bio::DB::EUtilities->new(
        -eutil  => 'elink',
        -id     => $ids,
        -db     => $target_db,
        -dbfrom => $src_db,
        -email  => $self->email
    );
    return $eutil->get_LinkInfo();
}

1;
