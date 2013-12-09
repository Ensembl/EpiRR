package EpiRR::Service::CommonMetaDataBuilder;

use Moose;

with 'EpiRR::Roles::MetaDataBuilder';

sub build_meta_data {
    my ( $sample_records, $errors ) = @_;
    my @samples = @$sample_records;
    confess 'Samples required' if ( !@samples );

    my $first_sample = pop @samples;
    my %meta_data    = $first_sample->all_meta_data();

    for my $s (@samples) {
        for my $k ( keys %meta_data ) {
            delete $meta_data{$k}
              if (!$s->meta_data_defined($k)
                || $s->get_meta_data($k) ne $meta_data{$k} );
        }
    }

    return \%meta_data;
}

__PACKAGE__->meta->make_immutable;
1;
