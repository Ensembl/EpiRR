use utf8;
package EpiRR::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07037 @ 2013-11-11 12:50:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PFXg+Br5giLTBZI/xYqRPg
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
