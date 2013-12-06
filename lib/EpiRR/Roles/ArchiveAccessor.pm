package EpiRR::Roles::ArchiveAccessor;

use Moose::Role;

requires 'lookup_raw_data';

has 'supported_archives' => (
    traits   => ['Array'],
    is       => 'rw',
    isa      => 'ArrayRef[Str]',
    required => 1,
    handles  => { all_supported_archives => 'elements' }
);

sub handles_archive {
    my ( $self, $archive ) = @_;

    my @matches = grep { $_ eq $archive } $self->all_supported_archives();

    if (@matches) {
        return 1;
    }
    else {
        return undef;
    }
}

1;
