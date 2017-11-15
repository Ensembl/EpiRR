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
use Data::Compare;
use EpiRR::Service::NcbiEUtils;
use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1; 
use feature qw(say);

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
    is  => 'rw',
    isa => 'MetaDataBuilder',

);
has 'dataset_classifier' => (
    is  => 'rw',
    isa => 'DatasetClassifier',

);
has 'eutils' => (
    is  => 'rw',
    isa => 'EpiRR::Service::NcbiEUtils',

);
has 'output_service' => (
    is  => 'rw',
    isa => 'EpiRR::Service::OutputService',

);

has 'schema' => ( is => 'rw', isa => 'EpiRR::Schema' );

# store data in database
sub user_to_db {
    my ( $self, $simple_dataset, $errors ) = @_;
    print ("simple_dataset: \n");
    print Dumper($simple_dataset);
    #print ("self: \n");
    #print Dumper($self);
    confess("No dataset provided") if ( !$simple_dataset );
    confess("Dataset must be EpiRR::Model::Dataset")
      if ( !$simple_dataset->isa('EpiRR::Model::Dataset') );
    confess("Must provide errors array ref")
      unless ( $errors && ref($errors) eq 'ARRAY' );
    # DBIx, Begin Transaction
    $self->schema()->txn_begin();

    if(length($simple_dataset->{accession}) > 0){
      my $acc = $simple_dataset->{accession};
      #print ("accession: \n");
      #print Dumper($acc);
      if($acc !~ /^IHECRE\d{8}$/){
        push @$errors, "Accession not in the correct format [IHEC12345678]:  $acc" ;
      }
    }

    my ( $dataset, $existing_dsv ) = $self->_dataset( $simple_dataset, $errors )
      #print ("existing_dsv: \n");
      #print Dumper($existing_dsv);
      if !@$errors;

    my $dataset_version =
      $self->_dataset_version( $simple_dataset, $dataset, $errors )
      #print ("dataset_version: \n");
      #print Dumper($dataset_version); 
     if !@$errors;

    my $samples = $self->_raw_data( $simple_dataset, $dataset_version, $errors )
      if !@$errors;
      print ("Samples : \n");
      print Dumper($samples);
    for (@$samples) {
        $self->_sample_species( $_, $errors );
    }


    $self->_create_meta_data( $dataset_version, $samples, $errors )
      if !@$errors;

    if ( !@$errors ) {
        my ( $status_name, $type_name ) =
          $self->dataset_classifier()
          ->determine_classification( $simple_dataset, $samples, $errors )
          unless @$errors;

        my $status =
          $self->schema()->status()->find( { name => $status_name } );
        #print ("Status : \n ");
	#print Dumper($status);
        my $type = $self->schema()->type()->find( { name => $type_name } );
        #print ("type \n");
	#print Dumper($status);
        $dataset_version->status($status);
        $dataset_version->type($type);
	#print ("dataset_version: \n");
	#print Dumper($dataset_version);
    }


    if ( !@$errors && $existing_dsv ) {
        my $existing_dataset =
	   $self->output_service->db_to_user($existing_dsv)->to_hash();
        my $new_dataset =
          $self->output_service->db_to_user($dataset_version)->to_hash();
	
	print ("existing_dataset \n");
	print Dumper($existing_dataset);
	

	print ("new_dataset \n");
        print Dumper($new_dataset);
        for ( $existing_dataset, $new_dataset ) {
            $_->{full_accession} = '';
            $_->{version}        = '';
        }

        my $comparison = Data::Compare->new( $existing_dataset, $new_dataset );
        if ( $comparison->Cmp() ) {

            #identical, so the update is unnecessary
            $self->schema()->txn_rollback();
            return $existing_dsv;
        }

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

sub _retrieve_and_check_dataset {
    my ( $self, $user_dataset, $errors ) = @_;
    # Q! Is this accessing the DB?
    # Q! Is find DBIx?
    my $dataset =
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

        my $declared_localname  = $user_dataset->local_name();
        my $retrieved_localname = $dataset->local_name();

        push @$errors,
          "Mismatch between local name declared ($declared_localname)"
          . " and that stored previously ($retrieved_localname)"
          if ( $retrieved_localname
            && $declared_localname
            && $declared_localname ne $retrieved_localname );
    }

    return $dataset;
}

sub _sample_species {
    my ( $self, $sample, $errors ) = @_;

    return if ( $sample->meta_data_exists('species') );

    if ( !$sample->meta_data_exists('taxon_id') ) {
        push @$errors,
          'No species or taxon ID for sample ' . $sample->sample_id();
        return;
    }

    my ($doc_sums) =
      $self->eutils()
      ->esummary( [ $sample->get_meta_data('taxon_id') ], 'taxonomy' );

    if ($doc_sums) {
        my ($species) = $doc_sums->get_contents_by_name('ScientificName');
        $sample->set_meta_data( 'species', $species );
    }
}

# Check if associated project exists
# If the DS has an accession
sub _dataset {
    my ( $self, $user_dataset, $errors ) = @_;

    my $project_name = $user_dataset->project();

    my $project = $self->schema()->project()->find( { name => $project_name } );
    push @$errors, "No project found for $project_name" if ( !$project );

    return if @$errors;

    my $dataset;
    # Check if name of datasets and the associated projects are the same
    if ( $user_dataset->accession() ) {
        $dataset = $self->_retrieve_and_check_dataset( $user_dataset, $errors );
    }
    elsif ( $user_dataset->local_name() ) {
      # Q! search_related DBIx?
        $dataset =
          $project->search_related( 'datasets',
            { local_name => $user_dataset->local_name() } )->single();
    }

    #else not looking for an existing dataset

    my $existing_dataset_version;
    if ($dataset) {
        $existing_dataset_version =
          $dataset->search_related( 'dataset_versions', { is_current => 1 } )
          ->single();
    }
    else {
        $dataset = $self->schema()->dataset()->create(
            {
                local_name => $user_dataset->local_name(),
                project    => $project,
            }
        );
    }
    return ( $dataset, $existing_dataset_version );
}

sub _dataset_version {
    my ( $self, $user_dataset, $dataset, $errors ) = @_;

    my $dataset_version = $self->schema->dataset_version()->create(
        {
            status => $self->schema()->status()->find( { name => 'DEFAULT' } ),
            type   => $self->schema()->type()->find(   { name => 'DEFAULT' } ),
            description => $user_dataset->description(),
            dataset     => $dataset,
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
         
           # print "raw data:\n";
           # print Dumper($rd);
                      

            if ( !@$rd_errors ) {
                #no errors, should have objects
                confess("No raw data returned for $rd_txt") unless $rd;
                confess("No sample returned for $rd_txt")   unless $s;

                push @$rd_errors, "No experiment type found for $rd_txt"
                  unless ( $rd->experiment_type() );
                push @$rd_errors, "No assay type found for $rd_txt"
                  unless ( $rd->assay_type() );
            }


            push @samples, $s if ($s);

            $dataset_version->create_related(
                'raw_datas',
                {
                    primary_accession   => $rd->primary_id(),
                    secondary_accession => $rd->secondary_id(),
                    archive             => $archive,
                    archive_url         => $rd->archive_url(),
                    experiment_type     => $rd->experiment_type(),
                    assay_type          => $rd->assay_type(),
                    extraction_protocol => $rd->extraction_protocol()
		}
            ) if ( !@$rd_errors );

            $user_rd->experiment_type( $rd->experiment_type() ) if ($rd && $rd->experiment_type);
            $user_rd->assay_type( $rd->assay_type ) if ($rd && $rd->experiment_type);
        }

        if ( ! $self->accessor_exists($archive_name) ) {
            push @$rd_errors, "Do not know how to read raw data from archive";
        }

        push @$errors, map { "$rd_txt: $_" } @$rd_errors;
    }

    push @$errors, "No samples found" unless @samples;

    return \@samples;
}

__PACKAGE__->meta->make_immutable;
1;
