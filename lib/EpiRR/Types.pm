package EpiRR::Types;

use Moose::Util::TypeConstraints;

role_type 'ArchiveAccessor', { role => 'EpiRR::Roles::ArchiveAccessor' };
role_type 'HasErrors',       { role => 'EpiRR::Roles::HasErrors' };
role_type 'HasMetaData',     { role => 'EpiRR::Roles::HasMetaData' };
role_type 'HasUserAgent',    { role => 'EpiRR::Roles::HasUserAgent' };

1;
