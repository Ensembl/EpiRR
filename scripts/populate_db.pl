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
use Carp;
use Getopt::Long;

my $config_module = 'EpiRR::Config';

GetOptions(
    "config=s" => \$config_module,
);

eval("require $config_module") or croak "cannot load module $config_module $@";

my $container = $config_module->c();
my $schema = $container->resolve( service => 'database/dbic_schema' );
croak("Cannot find schema") unless ($schema);

# load type and status names from those supported by this app config
my $classifier = $container->resolve( service => 'dataset_classifier' );
croak("Cannot find classifier") unless ($classifier);

for my $status_name ( 'DEFAULT', $classifier->all_status_names() ) {
    my $existing_status = $schema->status()->find( { name => $status_name } );
    if ( !$existing_status ) {
        $schema->status()->create( { name => $status_name, } );
    }
}

for my $type_name ( 'DEFAULT', $classifier->all_type_names() ) {
    my $existing_type = $schema->type()->find( { name => $type_name } );
    if ( !$existing_type ) {
        $schema->type()->create( { name => $type_name, } );
    }
}

# raw data archives
my %archives = (
    'EGA'   => 'European Genome-phenome archive',
    'ENA'   => 'European Nucelotide Archive',
    'SRA'   => 'NCBI Sequence Read Archive',
    'DDBJ'  => 'DNA Data Bank of Japan',
    'AE'    => 'ArrayExpress',
    'GEO'   => 'Gene Expression Omnibus',
    'DBGAP' => 'NCBI dbGaP',
);

while ( my ( $name, $full_name ) = each %archives ) {
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

# ensure we can support all archives in current config
my $conversion_service = $container->resolve( service => 'conversion_service' );
for my $name ( $conversion_service->all_archives() ) {
    my $archive = $schema->archive()->find( { name => $name } );
    if ( !$archive ) {
        croak(
"Conversion service supports archive $name, but this is not in the DB"
        );
    }
}

#create project names
my %projects = (
    'BLUEPRINT'   => 'IHECRE',
    'DEEP'        => 'IHECRE',
    'EPP'         => 'IHECRE',
    'NIH Roadmap' => 'IHECRE',
    'CREST'       => 'IHECRE',
    'CEMT'        => 'IHECRE'
);

while ( my ( $name, $id_prefix ) = each %projects ) {
    my $existing_project = $schema->project()->find( { name => $name } );
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
