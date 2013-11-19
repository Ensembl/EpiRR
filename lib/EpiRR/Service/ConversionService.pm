package EpiRR::Service::RawDataService;

use strict;
use warnings;
use Moose;
use Carp;

has 'raw_data_service' => (
    is       => 'rw',
    isa      => 'EpiRR::Service::RawDataService',
    required => 1,
);
has 'meta_data_service' => (
is => 'rw',
isa => 'EpiRR::Service::MetaDataService',
required => 1,
);
has 'model' => { is => 'rw', isa => 'EpiRR::Model', required => 1 };


#has 'project'   => ( is => 'rw', isa => 'Str', predicate => 'has_project' );
#has 'status'    => ( is => 'rw', isa => 'Str', predicate => 'has_status' );
#has 'accession' => ( is => 'rw', isa => 'Str', predicate => 'has_accession' );
#has 'local_name'  => ( is => 'rw', isa => 'Str' );
#has 'description' => ( is => 'rw', isa => 'Str' );
#raw_data
#meta_data

sub db_to_simple {
    my ( $self, $dsv ) = @_;

    croak("No DatasetVersion passed") unless $dsv;
    croak("Argument must be a DatasetVersion")
      unless $dsv->isa("EpiRR::Model::Result::DatasetVersion");
      
      
    my $d = EpiRR::Model::DataSet->new(
      project => $dsv->dataset()->project()->name(),
      status => $dsv->status();
      accession => $dsv->full_accession(),
      local_name => $dsv->local_name(),
      description => $dsv->description()
    );
    
    $d->meta_data(  );
    
    return $d;  
}

sub simple_to_db {

}

__PACKAGE__->meta->make_immutable;
1;
