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
use Mojolicious::Lite;
use Carp;

use EpiRR::Schema;
use EpiRR::Service::OutputService;
use EpiRR::App::Controller;

plugin 'Config';

my $db = app->config('db');

my $schema = EpiRR::Schema->connect( $db->{dsn}, $db->{user}, $db->{password}, )
  || die "Could not connect";

my $os = EpiRR::Service::OutputService->new( schema => $schema );
my $controller =
  EpiRR::App::Controller->new( output_service => $os, schema => $schema );

get '/view/all' => sub {
    my $self = shift;
    $self->render( json => $controller->fetch_current() );
};

get '/view/decorated/all' => sub {
    my $self = shift;
    $self->render( json => $controller->fetch_decorated_current() );
};

get '/view/:id' => sub {
    my $self    = shift;
    my $id      = $self->param('id');
    my $dataset = $controller->fetch($id);
    if ($dataset) {
        $self->render( json => $dataset );
    }
    else {
        $self->res->code(404);
        $self->res->message('Not Found');
        $self->render();
    }
};

# Start the Mojolicious command system
app->start;
