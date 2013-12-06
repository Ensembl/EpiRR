package EpiRR::Model::RawData;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

has 'archive'      => ( is => 'rw', isa => 'Str' );
has 'primary_id'   => ( is => 'rw', isa => 'Str' );
has 'secondary_id' => ( is => 'rw', isa => 'Str' );
has 'archive_url'  => ( is => 'rw', isa => 'Str' );
has 'experiment_type' => ( is => 'rw', isa => 'Str' );
has 'sample' => (is => 'rw', isa => 'EpiRR::Model::Sample');

sub as_string {
  my ($self) = @_;
  my $na = '-';
  return join(' ',$self->archive() || $na, $self->primary_id() || $na, $self->secondary_id() || $na);
}

__PACKAGE__->meta->make_immutable;
1;
