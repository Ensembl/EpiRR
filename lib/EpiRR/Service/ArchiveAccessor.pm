package EpiRR::Service::ArchiveAccessor;

use Moose::Role;

requires 'lookup_experiment';
requires 'lookup_sample';

has 'supported_archives' => (
    traits => ['Array'],
    is 'ro',
    is 'ArrayRef[Str]',
    handles => {
        all_supported_archives  => 'elements',
        grep_supported_archives => 'grep',
    },
);

sub handles_archive {
    my ( $self, $archive ) = @_;

    my @matches = $self->grep_supported_archives( sub { $_ eq $archive } );

    if (@matches) {
        return 1;
    }
    else {
        return undef;
    }
}

1;
