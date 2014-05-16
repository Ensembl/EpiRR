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
use strict;
use warnings;

use Test::More;
use Data::Dumper;
use EpiRR::Model::Sample;

my $expected = { 'foo' => 'BAR', 'heh' => 'ho', 'fee' => 'fi' };

{
    my $s =
      EpiRR::Model::Sample->new(
        meta_data => { 'FOO' => 'BAR', 'HEH' => 'ho', 'fee' => 'fi' } );

    is_deeply( $s->meta_data, $expected, 'Set in constructor' );
}

{
    my $s =
      EpiRR::Model::Sample->new();
      $s->meta_data({ 'FOO' => 'BAR', 'HEH' => 'ho', 'fee' => 'fi' } );

    is_deeply( $s->meta_data, $expected, 'Set in method' );
}

{
    my $s =
      EpiRR::Model::Sample->new();
      $s->set_meta_data( 'FOO' => 'BAR',);
      $s->set_meta_data('HEH' => 'ho',);
      $s->set_meta_data('fee' => 'fi',);

    is_deeply( $s->meta_data, $expected, 'Set in trait method' );
}
done_testing();


