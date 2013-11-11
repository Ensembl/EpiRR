package EpiRR::Parser::TextFileParser;

use strict;
use warnings;
use autodie;
use Moose;

=head1 NAME

EpiRR::Parser::TextFileParser

=cut

has 'schema' { is => 'ro', isa => 'EpiRR::Schema' }

  sub parse {
    my ( $self, $file_path ) = @_;

    $self->open($file_path);

    my $dataset_version = $self->schema()->dataset_version()->new();
    my @errors;

    my ( @project, @dataset, @rawdata );

    while ( my ( $type, $tokens ) = $self->next_token_set() ) {

        if ( $type eq 'PROJECT' ) {
            my $project =
              $self->schema()->project()->find( { name => $tokens->[0] } );
            if ($project) { push @projects, $project; }
            else {
                push @errors,
                    'Cannot find project for '
                  . $tokens->[0]
                  . ' at line '
                  . $fh->input_line_number;
            }

            # multiple projects
        }
        if ( $type eq 'RAW_DATA' ) {
            my ( $archive_name, $primary_id, $secondary_id ) = @$tokens;

            $archive =
              $self->schema()->archive()->find( { name => $archive_name } );

            # malformed archive name?

            push @rawdata, $self->schema()->raw_data()->new(
                {
                    archive             => $archive_name,
                    primary_accession   => $primary_id,
                    secondary_accession => $secondary_id,
                }
            );
        }

        if ( $type eq 'DATASET' ) {
            $dataset =
              $self->schema()->dataset()->find( accession => $tokens->[0] );

            # cannot find dataset
        }

        if ( $type eq 'LOCAL_NAME' ) {
            $dataset_version->local_name( $tokens->[0] );

            # multiple local_names
        }

        if ( $type eq 'DESCRIPTION' ) {
            $dataset_version_ > description( $tokens->[0] );

            # multiple descriptions
        }

    }

    if ( !$dataset ) {
        $dataset = $self->schema()->dataset()->new( project => $project );
    }

    $dataset_version->dataset($dataset);

    #missing project
    #mismatch between project and existing dataset project?
    #no raw data

    close $fh;

    return $dataset_version;
}

sub open {
    my ( $self, $file_path ) = @_;
    open my $fh, '<', $file_path;
    return $fh;
}

sub next_token_set {
    my ( $self, $fh ) = @_;

    my $type, @tokens;

    while (<$fh>) {
        chomp;
        next if /^#/;
        @tokens = split /\t/;
        $type   = shift @tokens;
        continue;
    }

    return $type, \@tokens;
}

1;
