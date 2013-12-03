package EpiRR::Service::MetaDataService;

use strict;
use warnings;
use Moose;
use Carp;

sub convert_to_simple {
    my ( $self, $mds ) = @_;

    croak("No MetaData passed") unless $md;

    my %meta_data;

    for my $meta_data (@$mds) {
        croak("Argument must be a DatasetVersion")
          unless $md->isa("EpiRR::Schema::Result::MetaData");
          
          $
    }

    return \%meta_data;
}

__PACKAGE__->meta->make_immutable;
1;
