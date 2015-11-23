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
use Carp;
use JSON;

my $config_module = 'EpiRR::Config';
my $file;
my $outfile;
my $errfile;
my $overwrite = 0;

GetOptions(
    "config=s"   => \$config_module,
    "file=s"     => \$file,
    "outfile=s"  => \$outfile,
    "errfile=s"  => \$errfile,
    "overwrite!" => \$overwrite,
) or croak("Error with options: $!");

croak("Missing option: -file") unless $file;

eval("require $config_module") or croak "cannot load module $config_module $@";

my $container = $config_module->c();

my $accession_service = $container->resolve( service => 'accession_service' );
croak("Cannot find accession_service") unless ($accession_service);

if ( !$outfile ) {
    $outfile = $file . '.out.json';
}

if ( !$errfile ) {
    $errfile = $file . '.err';
}

my ( $errors, $dataset, ) =
  $accession_service->accession( $file, $outfile, $errfile, 0 );

if (@$errors) {
    print STDERR
      "Error(s) when checking and storing data set, will not proceed." . $/;
    exit 2;
}
exit 0;
