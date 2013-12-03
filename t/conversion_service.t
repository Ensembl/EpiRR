#!/usr/bin/env perl
use strict;
use warnings;

use EpiRR::Service::ConversionService;
use EpiRR::Service::ENAWeb;

use Test::More;

my $ew = EpiRR::Service::ENAWeb->new();
my $cs = EpiRR::Service::ConversionService->new();
$cs->set_accessor( 'ENA',  $ew );
$cs->set_accessor( 'SRA',  $ew );
$cs->set_accessor( 'DDBJ', $ew );




done_testing();