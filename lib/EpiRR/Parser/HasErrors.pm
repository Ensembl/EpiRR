package EpiRR::Parser::HasErrors;

use Moose::Role;


has 'errors' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    handles => {
        push_error   => 'push',
        error_count  => 'count',
        get_error    => 'get',
        clear_errors => 'clear'
    },
    default => sub { [] }
);




1;