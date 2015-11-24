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
use utf8;

plugin 'Config';

my $db = app->config('db');

my $schema = EpiRR::Schema->connect( $db->{dsn}, $db->{user}, $db->{password}, )
  || die "Could not connect";

my $os = EpiRR::Service::OutputService->new( schema => $schema );
my $controller =
  EpiRR::App::Controller->new( output_service => $os, schema => $schema );

get '/summary' => sub {
    my $self = shift;

    my $summary = $controller->fetch_summary();

    $self->respond_to(
        json => sub { $self->render( json => $summary ); },
        html => sub {
            $self->stash( summary => $summary, title => 'dataset summary', );
            $self->render( template => 'summary' );
        }
    );
};

get '/view/all' => sub {
    my $self = shift;

    my $datasets = $controller->fetch_current();

    $self->respond_to(
        json => sub {
            my @hash_datasets;
            for my $d (@$datasets) {
                my $url            = $self->req->url->to_abs;
                my $path           = $url->path;
                my $hd             = $d->to_hash;
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
            $self->stash( datasets => $datasets, title => 'datasets', );
            $self->render( template => 'viewall' );
        },
    );

};

get '/view/#id' => sub {
    my $self    = shift;
    my $id      = $self->param('id');
    my $dataset = $controller->fetch($id);

    my $url  = $self->req->url->to_abs;
    my $acc = $dataset->accession;
    my $this_version = $dataset->full_accession;
    my $path = $url->path;

    my $links = { self => {href => $url},  };

    if ( $dataset->version > 1 ) {
        my $prev_url = $url;
        my $prev_version = $dataset->accession . '.' . ($dataset->version - 1 );
        
        if ($prev_url !~ s/$this_version/$prev_version/){
          $prev_url =~ s/$acc/$prev_version/
        }        
        
        $links->{previous_version} = $prev_url;
    }

    if ( ! $dataset->is_current ){
      my $curr_url = $url;
      $curr_url =~ s/$this_version/$acc/;
      $links->{current_version} = {href => $curr_url}; 
    }

    if ( !$dataset ) {
        $self->reply->not_found;
        return;
    }
    $self->respond_to(
        json => sub {
            my $hd = $dataset->to_hash;
            $hd->{_links} = $links;
            $self->render( json => $hd );
        },
        html => sub {
            $self->stash(
                dataset => $dataset,
                current_url   => $links->{current_version}{href},
                previous_url   => $links->{previous_version}{href},
                title   => 'dataset ' . $dataset->full_accession,
            );
            $self->render( template => 'viewid' );
        },
    );
};

get '/' => sub {
    my $self = shift;
    my $url            = $self->req->url->to_abs;
    $self->render( template => 'index', title => '', url => $url );
};

# Start the Mojolicious command system
app->start;

__DATA__
@@ layouts/layout.html.ep
<!DOCTYPE html>
<html>
<head>
<title>EpiRR <%= $title %></title>
<link href="../favicon.ico" rel="icon" type="image/x-icon" />
<!-- Latest compiled and minified CSS -->
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css">
<!-- Optional theme -->
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap-theme.min.css">
</head>
<body>
<div class="container-fluid">
<%= content %>
</div>
<!-- Latest compiled and minified JavaScript -->
<script src="https://code.jquery.com/jquery-1.11.3.min.js"></script>
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"></script>
</body>
</html>


@@ index.html.ep
% layout 'layout';
<h1>EpiRR REST API</h1>
<h2>Endpoints</h2>
<dl class="dl-horizontal">
<dt><a href="<%= $url %>summary">/summary</a></dt>
<dd>Report summary stats</dd>
<dt><a href="<%= $url %>view/all">/view/all</a></dt>
<dd>List all current datasets</dt>
<dt>/view/:id</dt>
<dd>View the detail of one reference dataset</dt>
</dl>
<h2>Response types</h2>
<p>Append <code>?format=<var>x</var></code> to the end of your query to control the format.</p>
<p>Formats available:</p>
<ul>
<li>json</li>
<li>html</li>
</ul>
<p>Alternatively, use the <a href="http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html">"Accept"</a> header in your HTTP request.</p>

@@ viewid.html.ep
% layout 'layout';
<h1><%= $dataset->full_accession %></h1>
<dl class="dl-horizontal">
  <dt>Type</dt><dd><%= $dataset->type %></dd>
  <dt>Status</dt><dd><%= $dataset->status %></dd>
  <dt>Project</dt><dd><%= $dataset->project %></dd>
  <dt>Local name</dt><dd><%= $dataset->local_name %></dd>
  <dt>Description</dt><dd><%= $dataset->description %></dd>
  <dt>Is live version?</dt><dd><%= $dataset->is_current ? 'yes' : 'no' %></dd>
% if ($current_url || $previous_url) {
  <dt>Other versions</dt>
% if ($current_url) {
  <dd><a href="<%= $current_url%>">live</a></dd>
%}
% if ($previous_url) {
  <dd><a href="<%= $previous_url%>">previous</a></dd>
%}
%}
</dl>
<h2>Metadata</h2>
<dl class="dl-horizontal">
% for my $kv ($dataset->meta_data_kv) {
  <dt><%= $kv->[0] %></dt><dd><%= $kv->[1] %></dd>  
% }
</dl>
<h2>Raw data</h2>
<table class="table table-hover table-condensed table-striped">
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

@@ viewall.html.ep
% layout 'layout';
<h1>EpiRR datasets</h1>
<table class="table table-hover table-condensed table-striped">
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

@@ summary.html.ep
% layout 'layout';
<h1>EpiRR dataset summary</h1>
<table class="table table-hover table-condensed table-striped">
<thead>
<tr>
<th>Project</th>
<th>Status</th>
<th>Dataset Count</th>
<th></th>
</tr>
</thead>
<tbody>
% for my $s (@$summary) {
  <tr>
  <td><%= $s->{project} %></td>
  <td><%= $s->{status} %></td>
  <td><%= $s->{dataset_count} %></td>
  </tr>
% }
</tbody>
</table>
