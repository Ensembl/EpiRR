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
package EpiRR::Service::ConversionService;

use Moose;
use namespace::autoclean;
use Carp;
use EpiRR::Types;
use EpiRR::Model::Dataset;
use EpiRR::Model::RawData;
use EpiRR::Service::CommonMetaDataBuilder;

has 'archive_services' => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef[ArchiveAccessor]',
    handles => {
        get_accessor    => 'get',
        set_accessor    => 'set',
        accessor_exists => 'defined',
        all_archives    => 'keys',
    },
    default => sub { {} },
);

has 'meta_data_builder' => (
    is       => 'rw',
    isa      => 'MetaDataBuilder',
    required => 1,
);
has 'dataset_classifier' => (
    is       => 'rw',
    isa      => 'DatasetClassifier',
    required => 1,
);

has 'schema' => ( is => 'rw', isa => 'EpiRR::Schema', required => 1 );

sub db_to_user {
    my ( $self, $dsv ) = @_;

    confess("No DatasetVersion passed") unless $dsv;
    confess("Argument must be a DatasetVersion")
      unless $dsv->isa("EpiRR::Schema::Result::DatasetVersion");

    my $d = EpiRR::Model::Dataset->new(
        project     => $dsv->dataset()->project()->name(),
        status      => $dsv->status()->name(),
        accession   => $dsv->full_accession(),
        local_name  => $dsv->local_name(),
        description => $dsv->description()
    );

    for my $m ( $dsv->meta_datas ) {
        $d->set_meta_data( $m->name(), $m->value() );
    }

    for my $r ( $dsv->raw_datas ) {
        my $x = EpiRR::Model::RawData->new(
            archive         => $r->archive()->name(),
            primary_id      => $r->primary_accession(),
            secondary_id    => $r->secondary_accession(),
            archive_url     => $r->archive_url(),
            experiment_type => $r->experiment_type(),
        );
        $d->add_raw_data($x);
    }

    return $d;
}

sub user_to_db {
    my ( $self, $simple_dataset, $errors ) = @_;

    confess("No dataset provided") if ( !$simple_dataset );
    confess("Dataset must be EpiRR::Model::Dataset")
      if ( !$simple_dataset->isa('EpiRR::Model::Dataset') );
    confess("Must provide errors array ref")
      unless ( $errors && ref($errors) eq 'ARRAY' );

    $self->schema()->txn_begin();

    my $dataset = $self->_dataset( $simple_dataset, $errors ) if !@$errors;
    
    
    my $dataset_version =
      $self->_dataset_version( $simple_dataset, $dataset, $errors ) if !@$errors;
      
    my $samples =
      $self->_raw_data( $simple_dataset, $dataset_version, $errors ) if !@$errors;

    $self->_create_meta_data( $dataset_version, $samples, $errors ) if !@$errors;

    if ( !@$errors ) {
        my ( $status_name, $type_name ) =
          $self->dataset_classifier()
          ->determine_classification( $simple_dataset, $samples, $errors )
          unless @$errors;

        my $status =
          $self->schema()->status()->find( { name => $status_name } );
        my $type = $self->schema()->type()->find( { name => $type_name } );

        $dataset_version->status($status);
        $dataset_version->type($type);
    }

    if (@$errors) {
        $self->schema()->txn_rollback();
        return undef;
    }
    else {
        $dataset_version->update();
        $self->schema()->txn_commit();
        return $dataset_version;
    }

}

sub _create_meta_data {
    my ( $self, $dataset_version, $sample_records, $errors ) = @_;

    confess("Dataset version required") unless ($dataset_version);
    confess("Dataset version must be EpiRR::Schema::Result::DatasetVersion")
      unless ( $dataset_version->isa('EpiRR::Schema::Result::DatasetVersion') );
    confess("Samples required") unless ( $sample_records && @$sample_records );

    my %meta_data =
      $self->meta_data_builder()->build_meta_data( $sample_records, $errors );

    if ( !%meta_data ) {
        push @$errors,
"No common meta data for this dataset, cannot determine what it represents";
    }

    while ( my ( $k, $v ) = each %meta_data ) {
        $dataset_version->create_related(
            'meta_datas',
            {
                name  => $k,
                value => $v,
            }
        );
    }

}

sub _dataset {
    my ( $self, $user_dataset, $errors ) = @_;

    my $project_name = $user_dataset->project();

    my $project = $self->schema()->project()->find( { name => $project_name } );
    push @$errors, "No project found for $project_name" if ( !$project );

    return if @$errors;

    my $dataset;
    if ( $user_dataset->accession() ) {
        $dataset =
          $self->schema()->dataset()
          ->find( { accession => $user_dataset->accession() } );

        push @$errors,
          "No dataset found for accession " . $user_dataset->accession()
          if ( !$dataset );

        if ($dataset) {
            my $declared_project  = $user_dataset->project();
            my $retrieved_project = $dataset->project()->name();

            push @$errors,
              "Mismatch between project declared ($declared_project)"
              . " and that stored previously ($retrieved_project)"
              if ( $declared_project ne $retrieved_project );
        }
    }
    elsif ($project) {
        $dataset = $project->create_related( 'datasets', {} );
    }
    return $dataset;
}

sub _dataset_version {
    my ( $self, $user_dataset, $dataset, $errors ) = @_;

    my $dataset_version = $dataset->create_related(
        'dataset_versions',
        {
            local_name  => $user_dataset->local_name(),
            description => $user_dataset->description(),
        }
    );

    return $dataset_version;
}

sub _raw_data {
    my ( $self, $user_dataset, $dataset_version, $errors ) = @_;

    my @samples;
    push @$errors, "No raw data listed"
      if ( !@{ $user_dataset->raw_data() } );
    return if @$errors;

    for my $user_rd ( @{ $user_dataset->raw_data() } ) {
        my $archive_name = $user_rd->archive();

        my $rd_errors = [];
        my $rd_txt    = $user_rd->as_string();
        my $archive =
          $self->schema()->archive()->find( { name => $archive_name } );

        if ( $self->accessor_exists($archive_name) ) {
            my $archive_accessor = $self->get_accessor($archive_name);

            my ( $rd, $s ) =
              $self->get_accessor($archive_name)
              ->lookup_raw_data( $user_rd, $rd_errors );

            if ( !@$rd_errors ) {
                confess("No raw data returned for $rd_txt") unless $rd;
                confess("No sample returned for $rd_txt")   unless $s;
            }

            push @samples, $s;

            $dataset_version->create_related(
                'raw_datas',
                {
                    primary_accession   => $rd->primary_id(),
                    secondary_accession => $rd->secondary_id(),
                    archive             => $archive,
                    archive_url         => $rd->archive_url(),
                    experiment_type     => $rd->experiment_type(),
                }
            ) if ( !@$rd_errors );
            $user_rd->experiment_type( $rd->experiment_type() );
        }
        else {
            push @$rd_errors, "Do not know how to read raw data from archive";
        }

        push @$errors, map { "$rd_txt: $_" } @$rd_errors;
    }

    push @$errors, "No samples found" unless @samples;

    return \@samples;
}

__PACKAGE__->meta->make_immutable;
1;
