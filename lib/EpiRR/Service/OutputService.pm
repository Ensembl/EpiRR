# Copyright 2015 European Molecular Biology Laboratory - European Bioinformatics Institute
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
package EpiRR::Service::OutputService;

use Moose;
use namespace::autoclean;
use Carp;
use EpiRR::Model::Dataset;
use EpiRR::Model::RawData;
use Data::Dumper;

has 'schema' => ( is => 'rw', isa => 'EpiRR::Schema', required => 1 );

sub db_to_user_summary {
    my ( $self, $dsv ) = @_;

    confess("No DatasetVersion passed") unless $dsv;
    confess("Argument must be a DatasetVersion")
      unless $dsv->isa("EpiRR::Schema::Result::DatasetVersion");

    my $d = EpiRR::Model::DatasetSummary->new(
        project        => $dsv->dataset()->project()->name(),
        status         => $dsv->status()->name(),
        full_accession => $dsv->full_accession(),
        accession      => $dsv->dataset()->accession(),
        version        => $dsv->version(),
        local_name     => $dsv->dataset()->local_name(),
        description    => $dsv->description(),
        type           => $dsv->type()->name
    );

    return $d;
}

sub db_to_user {
    my ( $self, $dsv ) = @_;

    confess("No DatasetVersion passed") unless $dsv;
    confess("Argument must be a DatasetVersion")
      unless $dsv->isa("EpiRR::Schema::Result::DatasetVersion");

    my $d = EpiRR::Model::Dataset->new(
        project        => $dsv->dataset()->project()->name(),
        status         => $dsv->status()->name(),
        full_accession => $dsv->full_accession(),
        accession      => $dsv->dataset()->accession(),
        version        => $dsv->version(),
        local_name     => $dsv->dataset()->local_name(),
        description    => $dsv->description(),
        type           => $dsv->type()->name(),
        is_current     => $dsv->is_current,
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
            assay_type      => $r->assay_type(),
        );

        for my $raw_meta_data ( $r->raw_meta_datas ) {  
	    $x->custom_field($raw_meta_data->name(), $raw_meta_data->value()); 
        }

        $d->add_raw_data($x);
    }

    return $d;
}

1;
