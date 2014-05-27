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
use strict;
use warnings;

use Test::More;
use Data::Dumper;
use EpiRR::Service::GeoWeb;
use EpiRR::Model::Sample;
use EpiRR::Model::RawData;

my $geo = EpiRR::Service::GeoWeb->new();

{
    my $errors    = [];
    my $accession = 'NO_DATA_HERE';
    my ( $raw_data, $sample ) = $geo->lookup_raw_data(
        EpiRR::Model::RawData->new(
            archive    => 'GEO',
            primary_id => $accession,
        ),
        $errors,
    );
    is_deeply(
        $errors,
        ['Geo returned no data for NO_DATA_HERE'],
        'Handles accession error'
    );
}

{
    my $accession = 'GSM409307';

    my $expected_sample = EpiRR::Model::Sample->new(
        sample_id => 'GSM409307',
        meta_data => {
            molecule               => 'genomic DNA',
            disease                => 'None',
            biomaterial_provider   => 'Cellular Dynamics International',
            biomaterial_type       => 'Cell Line',
            line                   => 'H1',
            lineage                => 'Embryonic Stem Cell',
            differentiation_stage  => 'None',
            differentiation_method => 'None',
            passage                => 'Between 30 and 50',
            medium                 => 'mTeSER',
            sex                    => 'Male',
            extraction_protocol =>
'See http://bioinformatics-renlab.ucsd.edu/RenLabChipProtocolV1.pdf',
            extraction_protocol_type_of_sonicator => 'Branson Tip Sonicator',
            extraction_protocol_sonication_cycles => '30',
            chip_protocol =>
'See http://bioinformatics-renlab.ucsd.edu/RenLabChipProtocolV1.pdf',
            chip_protocol_chromatin_amount => '500 micrograms',
            chip_protocol_bead_type        => 'magnetic anti-rabbit',
            chip_protocol_bead_amount      => '33,500,000',
            chip_protocol_antibody_amount  => '5 micrograms',
            chip_antibody                  => 'H3K4me1',
            chip_antibody_provider         => 'Abcam',
            chip_antibody_catalog          => 'ab8895',
            chip_antibody_lot              => '535659',
            taxon_id                       => 9606,
            species                        => 'Homo sapiens',
        },
    );

    my $expected_raw_data = EpiRR::Model::RawData->new(
        archive         => 'GEO',
        primary_id      => $accession,
        experiment_type => 'Histone H3K4me1',
        data_type       => 'ChIP-Seq',
        archive_url =>
          'http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM409307',
    );

    my ( $raw_data, $sample ) = $geo->lookup_raw_data(
        EpiRR::Model::RawData->new(
            archive    => 'GEO',
            primary_id => $accession,
        )
    );

    my $e_ok =
      is_deeply( $raw_data, $expected_raw_data, "Got expected experiment" );
    my $s_ok = is_deeply( $sample, $expected_sample, "Got expected sample" );

}

{
    my $accession = 'GSM706504';

    my $expected_sample = EpiRR::Model::Sample->new(
        sample_id => 'GSM706504',
        meta_data => {
            'disease'              => 'None',
            'biomaterial_provider' => 'FHCRC HEIMFELD',
            'biomaterial_type'     => 'Primary Cell',
            'cell_type'            => 'CD14 Primary Cells',
            'markers'              => 'CD14+',
            'donor_id'             => 'RO 01679',
            'donor_age'            => 'year 21',
            'donor_health_status'  => 'NA',
            'donor_sex'            => 'Male',
            'donor_ethnicity'      => 'Caucasian',
            'passage_if_expanded'  => 'NA',
            'taxon_id'             => 9606,
            'species'              => 'Homo sapiens',
        }
    );

    my $expected_raw_data = EpiRR::Model::RawData->new(
        archive    => 'GEO',
        primary_id => $accession,
        experiment_type =>
'[HuEx-1_0-st] Affymetrix Human Exon 1.0 ST Array [probe set (exon) version]',
        data_type =>
'[HuEx-1_0-st] Affymetrix Human Exon 1.0 ST Array [probe set (exon) version]',
        archive_url =>
          'http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM706504',
    );

    my ( $raw_data, $sample ) = $geo->lookup_raw_data(
        EpiRR::Model::RawData->new(
            archive    => 'GEO',
            primary_id => $accession,
        )
    );

    my $e_ok =
      is_deeply( $raw_data, $expected_raw_data, "Got expected experiment" );
    my $s_ok = is_deeply( $sample, $expected_sample, "Got expected sample" );
}

done_testing();
