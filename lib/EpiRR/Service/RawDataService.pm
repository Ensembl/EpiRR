package EpiRR::Service::RawDataService;

use Moose;
use namespace::autoclean;
use Carp;

has 'archive_services' => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef[EpiRR::Service::ArchiveService]',
    handles => {
        get_archive_service => 'get',
        set_archive_service => 'set',
    }
    default => sub { {} }
);


sub check {
  my ($self, $rd) = @_;
  
  croak("No RawData passed") unless $rd;
  croak("Argument must be a DatasetVersion")
    unless $rd->isa("EpiRR::Model::RawData");
  
}


__PACKAGE__->meta->make_immutable;
1;
