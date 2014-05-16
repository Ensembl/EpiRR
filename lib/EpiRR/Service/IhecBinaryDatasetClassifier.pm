# Copyright 2013 European Molecular Biology Laboratory - European Bioinformatics Institute
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
package EpiRR::Service::IhecBinaryDatasetClassifier;

use Moose;

with 'EpiRR::Roles::DatasetClassifier';

has '+status_names' => ( default => sub { [ 'Complete', 'Incomplete' ] }, );
has '+type_names' =>
  ( default => sub { [ 'Composite', 'Pooled samples', 'Single donor' ] }, );

has 'required_experiment_types' => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    traits  => ['Array'],
    default => sub {
        [
            'DNA Methylation',
            'ChIP-Seq Input',
            'Histone H3K4me1',
            'Histone H3K4me3',
            'Histone H3K9me3',
            'Histone H3K9ac',
            'Histone H3K27me3',
            'Histone H3K36me3',
            'mRNA-Seq',
        ];
    },
    handles => { 'all_required_experiment_types' => 'elements' }
);

sub determine_classification {
    my ( $self, $dataset, $samples, $errors ) = @_;

    my $completeness = $self->experimental_completeness( $dataset, $errors );
    my $composition = $self->composition( $samples, $errors );

    return ( $completeness, $composition );
}

sub composition {
    my ( $self, $samples, $errors ) = @_;
    my $dataset_type;
    my %donors;
    my %pools;

    for my $s (@$samples) {
        if ( $s->get_meta_data('pool_id') ) {
            $pools{ $s->get_meta_data('pool_id') }++;
        }
        elsif ( $s->get_meta_data('donor_id') || $s->get_meta_data('line') ) {
            $donors{ $s->get_meta_data('donor_id')
                  || $s->get_meta_data('line') }++;
        }
        else {
            push @$errors,
              'No donor_id/pool_id/line found for sample ' . $s->sample_id();
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

    return $dataset_type;
}

sub experimental_completeness {
    my ( $self, $dataset, $errors ) = @_;
    my %et;

    for my $rd ( $dataset->all_raw_data() ) {
        if ( $rd->experiment_type() ) {
            $et{ $rd->experiment_type() }++;
        }
        else {
            push @$errors, 'No experiment type for ' . $rd->primary_id();
        }
    }

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
