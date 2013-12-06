package EpiRR::Model::Sample;

use Moose;
use namespace::autoclean;

with 'EpiRR::Roles::HasMetaData';

has 'sample_id' => (is => 'rw', isa => 'Str');

1;