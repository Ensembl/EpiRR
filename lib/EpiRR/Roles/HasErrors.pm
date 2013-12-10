package EpiRR::Roles::HasErrors;

use Moose::Role;


has 'errors' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    handles => {
        push_error   => 'push',
        error_count  => 'count',
        get_error    => 'get',
        all_errors => 'elements',
    },
    default => sub { [] }
);




1;