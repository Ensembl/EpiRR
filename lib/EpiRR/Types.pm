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
package EpiRR::Types;

use Moose::Util::TypeConstraints;

role_type 'ArchiveAccessor',   { role => 'EpiRR::Roles::ArchiveAccessor' };
role_type 'DatasetClassifier', { role => 'EpiRR::Roles::DatasetClassifier' };
role_type 'MetaDataBuilder',   { role => 'EpiRR::Roles::MetaDataBuilder' };
role_type 'Throttler',         { role => 'EpiRR::Roles::Throttler' };
role_type 'HasErrors',         { role => 'EpiRR::Roles::HasErrors' };
role_type 'HasMetaData',       { role => 'EpiRR::Roles::HasMetaData' };
role_type 'HasUserAgent',      { role => 'EpiRR::Roles::HasUserAgent' };

1;
