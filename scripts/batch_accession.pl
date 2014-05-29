#!/usr/bin/env perl
# Copyright 2014 European Molecular Biology Laboratory - European Bioinformatics Institute
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
use File::Find;
use File::stat;

my $config_module = 'EpiRR::Config';
my $dir;
my $outfile;
my $quiet = 0;

GetOptions(
    "config=s" => \$config_module,
    "dir=s"    => \$dir,
    'quiet!'   => \$quiet,
) or croak("Error with options: $!");

croak("Missing option: -dir") unless ($dir);
croak("-dir $dir is not a directory") unless ( -d $dir );

eval("require $config_module")
  or croak "cannot load module $config_module $@";

my $container = $config_module->c();

# check container for dependencies
{
  my $text_file_parser = $container->resolve( service => 'text_file_parser' );
  croak("Cannot find text_file_parser") unless ($text_file_parser);

  my $json_file_parser = $container->resolve( service => 'json_file_parser' );
  croak("Cannot find json_file_parser") unless ($json_file_parser);

  my $conversion_service = $container->resolve( service => 'conversion_service' );
  croak("Cannot find conversion_service") unless ($conversion_service);

}
my $json = JSON->new();

find( \&wanted, $dir );

sub wanted {
    if ( (m/\.json$/ || m/.ref$/) && ! m/^\./) {
        my $in_file  = $File::Find::name;
        my $out_file = $File::Find::name . '.out';
        my $err_file = $File::Find::name . '.err';

        my $i_mod_time = stat($in_file)->mtime;
        my $o_mod_time = ( ( -e $out_file ) ? stat($out_file)->mtime : 0 );
        my $e_mod_time = ( ( -e $err_file ) ? stat($err_file)->mtime : 0 );
        
        if ( $i_mod_time > $o_mod_time && $i_mod_time > $e_mod_time ) {
            print STDOUT "Accessioning $in_file$/" unless $quiet;
            accession( $in_file, $out_file, $err_file );
        }
        else {
            print STDOUT "Skipping $in_file$/" unless $quiet;
        }
    }
}

sub accession {
    my ( $in_file, $out_file, $err_file ) = @_;

    open my $ofh, '>', $out_file or croak("Could not open $out_file: $!");
    open my $efh, '>', $err_file or croak("Could not open $err_file: $!");

    my $parser;

    if ( $in_file =~ m/\.json$/ ) {
        $parser = $container->resolve( service => 'json_file_parser' );
    }
    else {
        $parser = $container->resolve( service => 'text_file_parser' );
    }

    $parser->file_path($in_file);
    $parser->parse();

    if ( $parser->error_count() ) {
        print $efh "Error(s) when parsing file, accessioning will not proceed.$/";
        print $efh $_ . $/ for ( $parser->all_errors() );
        return;
    }
    
    my $conversion_service = $container->resolve( service => 'conversion_service' );
    my $user_dataset = $parser->dataset();
    my $errors       = [];
    my $db_dataset = $conversion_service->user_to_db( $user_dataset, $errors );

    if (@$errors) {
        print $efh
          "Error(s) when checking and storing data set, accessioning will not proceed." . $/;
        print $efh $_ . $/ for (@$errors);
        return;
    }

    my $full_dataset = $conversion_service->db_to_user($db_dataset);

    print $ofh $json->pretty()->encode( $full_dataset->to_hash() );

    close $ofh;
    close $efh;
    return;
}

