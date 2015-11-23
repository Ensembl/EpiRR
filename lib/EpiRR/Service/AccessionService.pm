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
package EpiRR::Service::AccessionService;

use Moose;
use namespace::autoclean;
use LWP;
use Carp;
use URI::Encode qw(uri_encode);
use BioSD;
use JSON;
use autodie;
use EpiRR::Parser::JsonParser;
use EpiRR::Parser::TextFileParser;

has 'json_parser' => (
    is      => 'rw',
    isa     => 'InputParser',
    default => sub { EpiRR::Parser::JsonParser->new() },
);

has 'text_parser' => (
    is      => 'rw',
    isa     => 'InputParser',
    default => sub { EpiRR::Parser::TextFileParser->new() },
);

has 'conversion_service' => (
    is       => 'rw',
    isa      => 'EpiRR::Service::ConversionService',
    required => 1,
);

has 'output_service' => (
    is       => 'rw',
    isa      => 'EpiRR::Service::OutputService',
    required => 1,
);

has 'json' => (
    is       => 'ro',
    isa      => 'JSON',
    required => 1,
    default  => sub {
        JSON->new()
    }
);

sub accession {
    my ( $self,$in_file, $out_file, $err_file, $quiet ) = @_;

    open my $ofh, '>', $out_file;
    open my $efh, '>', $err_file;

    my $errors = [];
    my @output = ($errors);

    my $parser;
    if ( $in_file =~ m/\.json$/ ) {
        $parser = $self->json_parser();
        print STDERR "Using JSON parser$/" unless $quiet;
    }
    else {
        $parser = $self->text_parser();
        print STDERR "Using text parser$/" unless $quiet;
    }

    $parser->file_path($in_file);
    $parser->parse();

    if ( $parser->error_count() ) {
        print $efh
          "Error(s) when parsing file, accessioning will not proceed.$/";
        print $efh $_ . $/ for ( $parser->all_errors() );
        push @$errors, $parser->all_errors;
        return @output;
    }

    my $user_dataset = $parser->dataset();
    push @output, $user_dataset;

    my $db_dataset =
      $self->conversion_service->user_to_db( $user_dataset, $errors );

    if (@$errors) {
        print $efh
"Error(s) when checking and storing data set, accessioning will not proceed."
          . $/;
        print $efh $_ . $/ for (@$errors);
        return @output;
    }

    my $full_dataset = $self->output_service->db_to_user($db_dataset);

    print $ofh $self->json->pretty()->encode( $full_dataset->to_hash() );

    close $ofh;
    close $efh;
    return @output;
}

1;
