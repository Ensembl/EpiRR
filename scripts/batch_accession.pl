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
use File::Find;
use File::Spec;
use File::Basename;
use autodie;

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
my $accession_service = $container->resolve( service => 'accession_service' );

my $report_file_name = "$dir/summary." . time . ".tsv";
open my $r_fh, '>', $report_file_name;
print $r_fh
  join( "\t", qw( File Project Local_name Description Status EpiRR_ID Errors ) )
  . $/;

find( \&wanted, $dir );

close $r_fh;

sub report {
  my ( $file_name, $errors, $ds ) = @_;

  my @cols = qw(file project local_name description status epirr_id);
  my %vals = (
    file        => basename($file_name),
    project     => ( $ds && $ds->project ) ? $ds->project : '',
    local_name  => ( $ds && $ds->local_name ) ? $ds->local_name : '',
    description => ( $ds && $ds->description ) ? $ds->description : '',
    status      => ( $ds && $ds->status ) ? $ds->status : '',
    epirr_id    => ( $ds && $ds->full_accession ) ? $ds->full_accession : '',
  );

  print $r_fh join( "\t", @vals{@cols}, @$errors ) . $/;

}

sub wanted {
  if ( ( m/\.refepi.json$/ || m/\.refepi$/ ) && !m/^\./ ) {
    my $in_file = $File::Find::name;

    my $out_file = $File::Find::name;
    $out_file =~ s/\.json$//;
    $out_file .= '.out.json';
    my $err_file   = $File::Find::name . '.err';
    my $i_mod_time = mtime($in_file);
    my $o_mod_time = ( ( -e $out_file ) ? mtime($out_file) : 0 );
    my $e_mod_time = ( ( -e $err_file ) ? mtime($err_file) : 0 );

    if ( $i_mod_time > $o_mod_time && $i_mod_time > $e_mod_time ) {
      print STDERR "Accessioning $in_file$/" unless $quiet;
      my ( $errors, $refepi ) =
        $accession_service->accession( $in_file, $out_file, $err_file, $quiet );
      report( $in_file, $errors, $refepi );
    }
    else {
      print STDERR "Skipping $in_file$/" unless $quiet;
    }
  }
}

sub mtime {
  my ($file) = @_;
  my @file_stat = stat $file or confess "stat failed for $file: " . $!;
  return $file_stat[9];
}
