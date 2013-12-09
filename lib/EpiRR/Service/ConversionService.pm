package EpiRR::Service::ConversionService;

use Moose;
use namespace::autoclean;
use Carp;
use EpiRR::Types;
use EpiRR::Model::Dataset;
use EpiRR::Model::RawData;
use Data::Dumper;

has 'archive_services' => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef[ArchiveAccessor]',
    handles => {
        get_accessor    => 'get',
        set_accessor    => 'set',
        accessor_exists => 'defined',
    },
    default => sub { {} },
);

has 'schema' => ( is => 'rw', isa => 'EpiRR::Schema' );

sub db_to_simple {
    my ( $self, $dsv ) = @_;

    confess("No DatasetVersion passed") unless $dsv;
    confess("Argument must be a DatasetVersion")
      unless $dsv->isa("EpiRR::Schema::Result::DatasetVersion");

    my $d = EpiRR::Model::Dataset->new(
        project     => $dsv->dataset()->project()->name(),
        status      => $dsv->status()->status(),
        accession   => $dsv->full_accession(),
        local_name  => $dsv->local_name(),
        description => $dsv->description()
    );

    for my $m ( $dsv->meta_datas ) {
        $d->set_meta_data( $m->name(), $m->value() );
    }

    for my $r ( $dsv->raw_datas ) {
        my $x = EpiRR::Model::RawData->new(
            archive      => $r->archive()->name(),
            primary_id   => $r->primary_id(),
            secondary_id => $r->secondary_id(),
            archive_url  => $r->archive_url,
        );
        $d->add_raw_data($x);
    }

    return $d;
}

sub simple_to_db {
    my ( $self, $simple_dataset ) = @_;

    confess("No dataset provided") if ( !$simple_dataset );
    confess("Dataset must be EpiRR::Model::Dataset")
      if ( !$simple_dataset->isa('EpiRR::Model::Dataset') );

    my $errors = [];

    $self->schema()->txn_begin();

    my $dataset = $self->_dataset( $simple_dataset, $errors );
    my $dataset_version =
      $self->_dataset_version( $simple_dataset, $dataset, $errors );
    my $samples =
      $self->_raw_data( $simple_dataset, $dataset_version, $errors );

    $self->_create_meta_data( $dataset_version, $samples, $errors );

    if (@$errors) {
        $self->schema()->txn_rollback();
        return $errors;
    }
    else {
        $self->schema()->txn_commit();
        return $dataset_version;
    }

}

sub _create_meta_data {
    my ( $self, $dataset_version, $sample_records, $errors ) = @_;
    my @samples = @$sample_records;
    confess 'Samples required' if ( !@samples );

    my $first_sample = pop @samples;
    my %meta_data    = $first_sample->all_meta_data();

    for my $s (@samples) {
        for my $k ( keys %meta_data ) {
            delete $meta_data{$k}
              if (!$s->meta_data_defined($k)
                || $s->get_meta_data($k) ne $meta_data{$k} );
        }
    }

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

    for my $user_rd ( @{ $user_dataset->raw_data() } ) {
        my $archive   = $user_rd->archive();
        my $rd_errors = [];
        push @$rd_errors, "Do not know how to read raw data from archive"
          if ( !$self->accessor_exists($archive) );

        next if !$self->accessor_exists($archive);

        my ( $rd, $s ) =
          $self->get_accessor($archive)
          ->lookup_raw_data( $user_rd, $rd_errors );

        my $rd_txt = $user_rd->as_string();
        push @$errors, map { "$rd_txt:$_" } @$rd_errors;
        push @samples, $s;

        $dataset_version->create_related(
            'raw_datas',
            {
                primary_accession   => $rd->primary_id(),
                secondary_accession => $rd->secondary_id(),
                archive             => $rd->archive(),
                archive_url         => $rd->archive_url(),
            }
        ) if ( !@$rd_errors );
    }

    return \@samples;
}

__PACKAGE__->meta->make_immutable;
1;
