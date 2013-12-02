package EpiRR::Model::Dataset;

use strict;
use warnings;

use Moose;

with 'EpiRR::Roles::HasMetaData';

has 'project' => (
    is        => 'rw',
    isa       => 'Maybe[Str]',
    default   => '',
    predicate => 'has_project'
);
has 'status' =>
  ( is => 'rw', isa => 'Maybe[Str]', default => '', predicate => 'has_status' );
has 'accession' => (
    is        => 'rw',
    isa       => 'Maybe[Str]',
    default   => '',
    predicate => 'has_accession'
);
has 'local_name'  => ( is => 'rw', isa => 'Maybe[Str]', default => '' );
has 'description' => ( is => 'rw', isa => 'Maybe[Str]', default => '' );

has 'raw_data' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef[EpiRR::Model::RawData]',
    handles => {
        all_raw_data   => 'elements',
        add_raw_data   => 'push',
        map_raw_data   => 'map',
        raw_data_count => 'count',
        has_raw_data   => 'count',
        get_raw_data   => 'get',
    },
    default => sub { [] },
);

__PACKAGE__->meta->make_immutable;
1;
