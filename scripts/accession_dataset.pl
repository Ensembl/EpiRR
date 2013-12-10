#!/usr/bin/env perl
use utf8;
use warnings;
use strict;

use EpiRR::Schema;
use Getopt::Long;
use Croak;

use Data::Dumper;

my $config_module = 'EpiRR::Config';
my $file;

GetOptions(
    "config=s" => \$config,
    "file=s"   => \$file,
);

eval "require $config_module" or throw "cannot load module $config_module $@";

my $container = $config_module->get_container();

my $text_file_parser = $container->resolve('textFileParser');
croak ("Cannot find textFileParser") unless $text_file_parser;

my $conversion_service = $container->resolve('conversionService');
croak ("Cannot find conversionService") unless $conversion_service;

$text_file_parser->file_path($file);
my $data$text_file_parser->parse();

if ($text_file_parser->error_count()) {
  print STDERR "Error(s) when parsing text file, will not proceed.".$/;
  print STDERR $_.$/ for ($text_file_parser->all_errors());
  exit 1;
}

my $user_dataset = $text_file_parser->dataset();
my $errors = []
my $db_dataset = $conversion_service->user_to_db($user_dataset,$errors);

if (@$errors){
  print STDERR "Error(s) when checking and storing data set, will not proceed.".$/;
  print STDERR $_.$/ for (@$errors);
  exit 2;
}

my $full_dataset = $conversion_service->db_to_user($db_dataset);

print STDOUT $full_dataset->full_accession;
exit 0;






