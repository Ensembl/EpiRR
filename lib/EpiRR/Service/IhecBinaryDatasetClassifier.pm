package EpiRR::Service::IhecBinaryDatasetClassifier;

use Moose;

with 'EpiRR::Roles::DatasetClassifier';

has 'required_experiment_types' => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    traits  => ['Array'],
    default => sub {
        [
            'DNA Methylation', 'ChIP-Seq Input',
            'Histone H3K4me1', 'Histone H3K4me3', 'Histone H3K9me3',
            'Histone H3K9ac', 'Histone H3K27me3', 'Histone H3K36me3', 'mRNA-Seq'
            ,
        ];
    },
    handles => { 'all_required_experiment_types' => 'elements' }
);

sub determine_classification {
    my ( $self, $dataset_version, $samples, $errors ) = @_;

    my $completeness =
      $self->experimental_completeness( $dataset_version, $errors );
    my $composition = $self->composition( $samples, $errors );

    return ( $completeness, $composition );
}

sub composition {
    my ( $self, $samples, $errors ) = @_;
    my $dataset_type;
    my %donors;
    my %pools;

    for my $s (@$samples) {
        if ( $s->get_meta_data('POOL_ID') ) {
            $pools{ $s->get_meta_data('POOL_ID') }++;
        }
        elsif ( $s->get_meta_data('DONOR_ID') || $s->get_meta_data('LINE') ) {
            $donors{ $s->get_meta_data('DONOR_ID')
                  || $s->get_meta_data('LINE') }++;
        }
        else {
            push @$errors,
              'No DONOR_ID/POOL_ID/LINE found for sample ' . $s->sample_id();
        }
    }

    if ( scalar( keys %pools ) + scalar( keys %donors ) > 1 ) {
        $dataset_type = 'Composite';
    }
    elsif (%pools) {
        $dataset_type = 'Pooled samples';
    }
    elsif (%donors) {
        $dataset_type = 'Single donor';
    }
    else {
        push @$errors, 'No donor/line/pool information for dataset';
    }
}

sub experimental_completeness {
    my ( $self, $dataset_version ) = @_;
    my %et;
    $et{ $_->experiment_type() }++ for ( $dataset_version->raw_datas() );

    my $classification = 'Complete';

    for my $ret ( $self->all_required_experiment_types() ) {
        if ( !exists $et{$ret} ) {
            $classification = 'Incomplete';
        }
    }

    return $classification;
}

__PACKAGE__->meta->make_immutable;
1;
