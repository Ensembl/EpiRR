package EpiRR::Model::Dataset;

use strict;
use warnings;

use Moose;

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

has 'meta_data' => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef[Str]',
    handles => {
        get_meta_data      => 'get',
        set_meta_data      => 'set',
        delete_meta_data   => 'delete',
        meta_data_names    => 'keys',
        meta_data_exists   => 'exists',
        meta_data_defined  => 'defined',
        meta_data_values   => 'values',
        meta_data_kv       => 'kv',
        all_meta_data      => 'elements',
        meta_data_is_empty => 'is_empty',
    },
    default => sub { {} },
);

__PACKAGE__->meta->make_immutable;
1;
