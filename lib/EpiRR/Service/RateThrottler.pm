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
package EpiRR::Service::RateThrottler;

use Moose;
use Time::HiRes qw(gettimeofday sleep);

with 'EpiRR::Roles::Throttler';

has 'sampling_period_seconds' =>
  ( is => 'ro', isa => 'Num', required => 1, default => 1 );
has 'actions_permitted_per_period' =>
  ( is => 'ro', isa => 'Int', required => 1 );
has 'action_queue' => (
    is       => 'ro',
    isa      => 'ArrayRef[Num]',
    required => 1,
    default  => sub { [] },
    traits   => ['Array'],
    handles  => {
        queue_size    => 'count',
        _splice_queue => 'splice',
        _add          => 'unshift',
        _get          => 'get'
    },
);

sub do_action {
    my ($self) = @_;

    while ( $self->queue_size()
        && ( ($self->queue_size() + 1) > $self->actions_permitted_per_period() ) )
    {
        my $earliest_time       = $self->_get(-1);
        my $current_time        = gettimeofday();
        my $time_since_earliest = $current_time - $earliest_time;
        my $time_to_wait =
          $self->sampling_period_seconds() - $time_since_earliest;
        sleep($time_to_wait) if ($time_to_wait > 0);
        $self->_clean_queue();
    }

    my $current_time = gettimeofday();
    $self->_add($current_time);
}

sub _clean_queue {
    my ($self) = @_;

    my $current_time = gettimeofday();
    my $prune_limit  = $current_time - $self->sampling_period_seconds();
    my $q            = $self->action_queue();
    my $limit        = $self->queue_size();

    for ( my $i = 0 ; $i < $limit ; $i++ ) {
        if ( $q->[$i] < $prune_limit ) {
            $self->_splice_queue( $i, $limit - $i );
            last;
        }
    }
}
__PACKAGE__->meta->make_immutable;
1;
