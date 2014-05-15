# Copyright 2014 European Molecular Biology Laboratory - European Bioinformatics Institute
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
package EpiRR::App::Controller;
use Moose;

has 'conversion_service' => (
    is       => 'rw',
    isa      => 'EpiRR::Service::ConversionService',
    required => 1,
);

has 'schema' => ( is => 'rw', isa => 'EpiRR::Schema', required => 1 );

sub fetch_current {
  my ($self) = @_;
  
  my $cs = $self->conversion_service();
  my @current_data_sets = $self->schema()->dataset_version()->search({is_current => 1});
  my @dsv = map {$cs->db_to_user($_)} @current_data_sets;
  return \@dsv;  
}

1;