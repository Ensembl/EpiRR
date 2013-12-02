package EpiRR::Roles::HasUserAgent;

use Moose::Role;

has 'user_agent' => (
    is       => 'rw',
    isa      => 'LWP::UserAgent',
    required => 1,
    lazy     => 1,
    default =>
      sub { LWP::UserAgent->new( my $v = agent => "EpiRR/$EpiRR::VERSION" ); }
);

1;