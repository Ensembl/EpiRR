#!/usr/bin/env perl
# Copyright 2015 European Molecular Biology Laboratory - European Bioinformatics Institute
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
BEGIN {
    use FindBin qw/$Bin/;
    use lib "$Bin/lib";
}

use Test::More;
use EpiRR::DB::TestDB;
use EpiRR::IntegrationTestConfig;
use File::Temp qw(tempfile);
use File::Basename qw(dirname);
use Data::Dumper;

my $container = EpiRR::IntegrationTestConfig->c();
my $accession_service = $container->resolve( service => 'accession_service' );
ok($accession_service);

my $test_db = EpiRR::DB::TestDB->new();
my $schema  = $test_db->build_up();
$test_db->populate_basics();

$accession_service->output_service->schema($test_db->schema);
$accession_service->conversion_service->schema($test_db->schema);

my $test_file_dir = dirname(__FILE__) . '/datasets' ;


my (undef, $out_filename) = tempfile();
my (undef, $err_filename) = tempfile();


my ($errors,$output) = $accession_service->accession("$test_file_dir/rm_small.json",$out_filename,$err_filename);




done_testing();
