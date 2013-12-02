package EpiRR::Model::Sample;

use Moose;

with 'EpiRR::Model::HasMetaData';

has 'sample_id' => (is => 'rw', isa => 'Str');

1;