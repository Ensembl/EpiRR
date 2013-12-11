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
package EpiRR::Roles::HasMetaData;

use Moose::Role;

has 'meta_data' => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef[Str]',
    handles => {
        get_meta_data      => 'get',
        set_meta_data      => 'set',
        delete_meta_data   => 'delete',
        meta_data_names    => 'keys',
        meta_data_exists   => 'exists',
        meta_data_defined  => 'defined',
        meta_data_values   => 'values',
        meta_data_kv       => 'kv',
        all_meta_data      => 'elements',
        meta_data_is_empty => 'is_empty',
    },
    default => sub { {} },
);

1;