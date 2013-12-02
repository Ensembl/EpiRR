package EpiRR::Model::Sample;

use Moose;

with 'EpiRR::Roles::HasMetaData';

has 'sample_id' => (is => 'rw', isa => 'Str');

1;