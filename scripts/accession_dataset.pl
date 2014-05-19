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

GetOptions(
    "config=s"  => \$config_module,
    "file=s"    => \$file,
    "outfile=s" => \$outfile,
) or croak("Error with options: $!");

eval("require $config_module") or croak "cannot load module $config_module $@";

my $container = $config_module->c();

my $text_file_parser = $container->resolve( service => 'text_file_parser' );
croak("Cannot find text_file_parser") unless ($text_file_parser);

my $conversion_service = $container->resolve( service => 'conversion_service' );
croak("Cannot find conversion_service") unless ($conversion_service);

if ( !$outfile ) {
    $outfile = $file . '.out';
}

croak("Output would overwrite existing file $outfile") if (-e $outfile);
open my $fh, '>', $outfile or croak("Could not open $outfile: $!");

$text_file_parser->file_path($file);
$text_file_parser->parse();

if ( $text_file_parser->error_count() ) {
    print STDERR "Error(s) when parsing text file, will not proceed." . $/;
    print $fh $_.$/ for ( $text_file_parser->all_errors() );
    exit 1;
}

my $user_dataset = $text_file_parser->dataset();
my $errors       = [];
my $db_dataset   = $conversion_service->user_to_db( $user_dataset, $errors );

if (@$errors) {
    print STDERR
      "Error(s) when checking and storing data set, will not proceed." . $/;
    print $fh $_.$/ for ( @$errors );
    exit 2;
}

my $json = JSON->new();

my $full_dataset = $conversion_service->db_to_user($db_dataset);

print $fh $json->pretty()->encode($full_dataset->to_hash());

close $fh;
exit 0;
