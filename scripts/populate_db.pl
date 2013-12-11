#!/usr/bin/env perl
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
use warnings;
use strict;

use EpiRR::Schema;
use Getopt::Long;
use Data::Dumper;

my ( $db_url, $db_user, $db_pass, %db_params );

GetOptions(
    "dburl=s"   => \$db_url,
    "dbuser=s"  => \$db_user,
    "dbpass=s"  => \$db_pass,
    "dbparam=s" => \%db_params,
);

my $schema = EpiRR::Schema->connect( $db_url, $db_user, $db_pass );

for my $status_name (qw/COMPLETE IN_PROGRESS RETIRED/) {
    my $existing_status = $schema->status()->find( { status => $status_name } );
    if ( !$existing_status ) {
        $schema->status()->create( { status => $status_name, } );
    }
}

my @archives = (
    [ 'EGA', 'European Genome-phenome archive' ],
    [ 'ENA', 'European Nucelotide Archive' ],
    [ 'SRA', 'NIH Short Read Archive' ]
);

for my $archive (@archives) {
    my ( $name, $full_name ) = @$archive;
    my $existing_archive = $schema->archive()->find( { name => $name } );
    if ($existing_archive) {
        $existing_archive->full_name($full_name);
        $existing_archive->update();
    }
    else {
        $schema->archive()->create(
            {
                name      => $name,
                full_name => $full_name,
            }
        );
    }
}

my @projects = ( [ 'BLUEPRINT', 'BP' ], [ 'DEEP', 'DE' ], [ 'CEMT', 'CEMT' ], );

for my $project (@projects) {
    my ( $name, $id_prefix ) = @$project;
    my $existing_project = $schema->project()->find( { name => $name }
 );
    if ($existing_project) {
        $existing_project->id_prefix($id_prefix);
        $existing_project->update();
    }
    else {
        $schema->project->create(
            {
                name      => $name,
                id_prefix => $id_prefix,
            }
        );
    }
}