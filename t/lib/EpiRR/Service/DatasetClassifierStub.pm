package EpiRR::Service::DatasetClassifierStub;

use Moose;

with 'EpiRR::Roles::DatasetClassofier';

sub determine_classification {
  return (1,2);
}
__PACKAGE__->meta->make_immutable;
1;