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

use Test::More;
use EpiRR::Service::RateThrottler;
use Time::HiRes qw(gettimeofday tv_interval);

my $rt = EpiRR::Service::RateThrottler->new( actions_permitted_per_period => 3, sampling_period_seconds => 1 );

my $start_time = [gettimeofday];

for(1..9) {
  $rt->do_action();
} 

my $time_elapsed = tv_interval($start_time);

print $time_elapsed.$/;

# time elapsed is counter inutitive
# the 1st 3 actions happen early in second 0
# the 2nd 3 actions happen early in second 1
# the 3rd 3 actions happen early in second 2
# the time elapsed should be just over 2 seconds,
# while maintaining a rate below or at 3 requests per second at all times
ok($time_elapsed > 2,"Permissable action rate");

done_testing();