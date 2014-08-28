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
package EpiRR::Service::CommonMetaDataBuilder;

use Moose;

with 'EpiRR::Roles::MetaDataBuilder';

has 'required_meta_data' => (
    is      => 'rw',
    isa     => 'ArrayRef[ArrayRef[Str]]',
    traits  => ['Array'],
    default => sub {
        [
            ['species'],
            ['biomaterial_type'],
            [ 'pool_id', 'donor_id',  'line' ],
            [ 'line',    'cell_type', 'tissue_type' ],
        ];
    },
    handles => { 'all_required_data' => 'elements' }
);

sub build_meta_data {
    my ( $self, $sample_records, $errors ) = @_;
    my @samples = @$sample_records;
    confess 'Samples required' if ( !@samples );

    my $first_sample = pop @samples;
    my %meta_data    = $first_sample->all_meta_data();

    for my $s (@samples) {
      $self->check_minimal_meta_data($s,$errors);
        for my $k ( keys %meta_data ) {
            delete $meta_data{$k}
              if (!$s->meta_data_defined($k)
                || $s->get_meta_data($k) ne $meta_data{$k} );
        }
    }

    if ( !%meta_data ) {
        push @$errors, "No common meta data found between samples";
    }
    
    $self->clean_meta_data(\%meta_data);
    
    return %meta_data;
}

sub clean_meta_data {
  my ($self, $meta_data) = @_;
  
  my @unwanted_keys;
  for my $key (keys %$meta_data){
    if ($key =~ m/^ena-/){
      push @unwanted_keys, $key;
    }
  }
  
  delete @{$meta_data}{@unwanted_keys};
}

sub check_minimal_meta_data {
  my ($self, $s,$errors) = @_;
  
  for my $required_metadata ($self->all_required_data()){
    my $found = 0;
    for my $meta_data_opt (@$required_metadata){
      $found++ if ($s->meta_data_exists($meta_data_opt));
    }
    if (!$found){
      my $sid = $s->sample_id();
      push @$errors, "Meta data for sample $sid should include one of the following: ".join(', ', @$required_metadata);
    }
  }
}

__PACKAGE__->meta->make_immutable;
1;
