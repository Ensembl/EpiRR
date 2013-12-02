package EpiRR::Model::RawData;

use strict;
use warnings;

use Moose;

has 'archive' => (is => 'rw', isa => 'Str');
has 'primary_id' => (is => 'rw', isa => 'Str');
has 'secondary_id' => (is => 'rw', isa => 'Str');
has 'archive_url' => (is => 'rw', isa => 'Str');

has 'experiment_type' => (is => 'rw', isa => 'Str');

__PACKAGE__->meta->make_immutable;
1;