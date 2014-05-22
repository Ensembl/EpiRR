use utf8;
package EpiRR::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-05-22 14:35:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gwCg2FDo6HEk3PUZsl/xCQ

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
sub archive {
  return $_[0]->resultset('Archive');
}
sub dataset {
  return $_[0]->resultset('Dataset');
}
sub dataset_version {
  return $_[0]->resultset('DatasetVersion');
}
sub meta_data {
  return $_[0]->resultset('MetaData');
}
sub project {
  return $_[0]->resultset('Project');
}
sub raw_data {
  return $_[0]->resultset('RawData');
}
sub status {
  return $_[0]->resultset('Status');
}
sub type {
  return $_[0]->resultset('Type');
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
