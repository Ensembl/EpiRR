package EpiRR::Service::ArchiveAccessorStub;

use Moose;

with 'EpiRR::Roles::ArchiveAccessor';

sub lookup_raw_data {
    return 1;
}
has '+supported_archives' => ( default => sub { [ 'ENA', 'SRA', 'DDBJ', 'TA' ] }, );
__PACKAGE__->meta->make_immutable;
1;
