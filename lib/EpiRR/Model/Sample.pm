package EpiRR::Model::Sample;

use Moose;

with 'EpiRR::Model::HasMetaData';

has 'sample_id' => (is => 'rw', isa => 'Str');
has 'sample' => (is => 'rw' , isa=> 'EpiRR::Model::Sample');

1;