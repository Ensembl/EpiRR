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

sub build_meta_data {
    my ( $self, $sample_records, $errors ) = @_;
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

    if ( !%meta_data ) {
        push @$errors, "No common meta data found between samples";
    }

    return %meta_data;
}

__PACKAGE__->meta->make_immutable;
1;
