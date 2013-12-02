package EpiRR::Model::HasMetaData;

use Moose::Role;

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

1;