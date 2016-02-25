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

GetOptions( "config=s" => \$config_module, );

eval("require $config_module") or croak "cannot load module $config_module $@";

my $container = $config_module->c();
my $controller = $container->resolve( service => 'controller' );
croak("Cannot find controller") unless ($controller);

my @req = (
    'Bisulfite-Seq',
    'ChIP-Seq Input',
    'Histone H3K27me3',
    'Histone H3K36me3',
    'Histone H3K4me1',
    'Histone H3K4me3',
    'Histone H3K27ac',
    'Histone H3K9me3',
    'RNA-Seq'
);

my @columns = (qw(Project Accession Status Type Description),@req);

print join ("\t",@columns).$/;


for my $d ( @{ $controller->fetch_current } ) {

  my @v = ( $d->project, $d->full_accession, $d->status, $d->type,
      $d->description );

  my %rd;

  for my $r ( $d->all_rawdata ) {
      my $k =
        ( $r->assay_type eq 'ChIP-Seq' )
        ? $r->experiment_type
        : $r->assay_type;
      $rd{$k} = [] if ( !$rd{$k} );
      push @{ $rd{$k} }, $r->primary_accession;
  }

  for my $req (@req) {
      if ( $rd{$req} ) {
          push @v, join( ', ', @{ $rd{$req} } );
      }
      else {
          push @v, undef;
      }
  }

  print join( "\t", map { $_ // '' } @v ) . $/;
}
