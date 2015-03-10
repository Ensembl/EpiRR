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

    my $datasets = $controller->fetch_current();

    $self->respond_to(
        json => sub {
            my $url  = $self->req->url->to_abs;
            my $path = $url->path;

            my @hash_datasets;
            for my $d (@$datasets) {
                my $hd = $d->to_hash;
                my $full_accession = $d->full_accession;

                my $link_path = $path;
                $link_path =~ s!/view/all!/view/$full_accession!;
                $link_path =~ s/\.json$//;
                
                $url->path($link_path);
                
                $hd->{_links}{self} = "$url";
                push @hash_datasets, $hd;
            }

            $self->render( json => \@hash_datasets );
        },
        html => sub {
            $self->stash( datasets => $datasets );
            $self->render( template => 'viewall' );
        },
    );

};

get '/view/#id' => sub {
    my $self    = shift;
    my $id      = $self->param('id');
    my $dataset = $controller->fetch($id);

    if ( !$dataset ) {
        $self->reply->not_found;
        return;
    }
    $self->respond_to(
        json => { json => $dataset },
        html => sub {
            $self->stash( dataset => $dataset );
            $self->render( template => 'viewid' );
        },
    );
};

# Start the Mojolicious command system
app->start;

__DATA__

@@ viewid.html.ep
<!DOCTYPE html>
<html>
<head><title><%= $dataset->full_accession %></title></head>
<body>
<h1><%= $dataset->full_accession %></h1>
<dl>
  <dt>Type</dt><dd><%= $dataset->type %></dd>
  <dt>Status</dt><dd><%= $dataset->status %></dd>
  <dt>Project</dt><dd><%= $dataset->project %></dd>
  <dt>Local name</dt><dd><%= $dataset->local_name %></dd>
  <dt>Description</dt><dd><%= $dataset->description %></dd>
</dl>
<h2>Metadata</h2>
<dl>
% for my $kv ($dataset->meta_data_kv) {
  <dt><%= $kv->[0] %></dt><dd><%= $kv->[1] %></dd>  
% }
</dl>
<h2>Raw data</h2>
<table>
<thead>
<tr>
<th>Assay type</th>
<th>Experiment type</th>
<th>Archive</th>
<th>Primary ID</th>
<th>Secondary ID</th>
<th>Link</th>
</tr>
</thead>
<tbody>
% for my $rd ($dataset->all_raw_data) {
  <tr>
  <td><%= $rd->assay_type %></td>
  <td><%= $rd->experiment_type %></td>
  <td><%= $rd->archive %></td>
  <td><%= $rd->primary_id %></td>
  <td><%= $rd->secondary_id %></td>
  <td><a href="<%= $rd->archive_url %>">View in archive</a></td>
  </tr>
% }
</tbody>
</table>
</body>
</html>

@@ viewall.html.ep
<!DOCTYPE html>
<html>
<head><title>EpiRR Datasets</title></head>
<body>
<h1>EpiRR Datasets</h1>
<table>
<thead>
<tr>
<th>Project</th>
<th>Type</th>
<th>Status</th>
<th>ID</th>
<th>Local name</th>
<th>Description</th>
<th></th>
</tr>
</thead>
<tbody>
% for my $d (@$datasets) {
  <tr>
  <td><%= $d->project %></td>
  <td><%= $d->type %></td>
  <td><%= $d->status %></td>
  <td><%= $d->full_accession %></td>
  <td><%= $d->local_name %></td>
  <td><%= $d->description %></td>
  <td><a href="./<%= $d->full_accession %>">Detail</a></td>
  </tr>
% }
</tbody>
</table>
</body>
</html>
