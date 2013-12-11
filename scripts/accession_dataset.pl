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
use utf8;
use warnings;
use strict;

use EpiRR::Schema;
use Getopt::Long;
use Carp;

use Data::Dumper;

my $config_module = 'EpiRR::Config';
my $file;

GetOptions(
    "config=s" => \$config_module,
    "file=s"   => \$file,
);

eval("require $config_module") or croak "cannot load module $config_module $@";

my $container = $config_module->c();

my $text_file_parser = $container->resolve( service => 'textFileParser');
croak ("Cannot find textFileParser") unless ($text_file_parser);

my $conversion_service = $container->resolve( service => 'conversionService');
croak ("Cannot find conversionService") unless ($conversion_service);

$text_file_parser->file_path($file);
$text_file_parser->parse();

if ($text_file_parser->error_count()) {
  print STDERR "Error(s) when parsing text file, will not proceed.".$/;
  print STDERR $_.$/ for ($text_file_parser->all_errors());
  exit 1;
}

my $user_dataset = $text_file_parser->dataset();
my $errors = [];
my $db_dataset = $conversion_service->user_to_db($user_dataset,$errors);

if (@$errors){
  print STDERR "Error(s) when checking and storing data set, will not proceed.".$/;
  print STDERR $_.$/ for (@$errors);
  exit 2;
}

my $full_dataset = $conversion_service->db_to_user($db_dataset);

print STDOUT $full_dataset->full_accession;
exit 0;