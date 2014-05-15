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
use EpiRR::Service::GeoEutils;
use EpiRR::Model::Sample;
use EpiRR::Model::RawData;
use EpiRR::Service::NcbiEutils;
use EpiRR::Service::SRAEUtils;

my $eu = EpiRR::Service::NcbiEutils->new( email => 'davidr@ebi.ac.uk' );
my $sra = EpiRR::Service::SRAEUtils->new( eutils => $eu );
my $ge = EpiRR::Service::GeoEutils->new( eutils => $eu, sra_accessor => $sra, );

{
    my $accession = 'GSM409307';

    my $expected_sample = EpiRR::Model::Sample->new(
        sample_id => 'SRS004118',
        meta_data => {
            'DIFFERENTIATION_METHOD' => 'None',
            'SPECIES'                => 'Homo sapiens',
            'DISEASE'                => 'None',
            'MOLECULE'               => 'genomic DNA',
            'LINEAGE'                => 'Embryonic Stem Cell',
            'BIOMATERIAL_PROVIDER'   => 'Cellular Dynamics International',
            'BIOMATERIAL_TYPE'       => 'Cell Line',
            'SEX'                    => 'Male',
            'PASSAGE'                => 'Between 30 and 50',
            'DIFFERENTIATION_STAGE'  => 'None',
            'MEDIUM'                 => 'mTeSER',
            'LINE'                   => 'H1'
        }
    );

    my $expected_raw_data = EpiRR::Model::RawData->new(
        archive         => 'GEO',
        primary_id      => $accession,
        experiment_type => 'Histone H3K4me1',
        archive_url =>
          'http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM409307',
    );

    my ( $raw_data, $sample ) = $ge->lookup_raw_data(
        EpiRR::Model::RawData->new(
            archive    => 'GEO',
            primary_id => $accession,
        )
    );

    my $e_ok =
      is_deeply( $raw_data, $expected_raw_data, "Got expected experiment" );
    my $s_ok = is_deeply( $sample, $expected_sample, "Got expected sample" );

  SKIP: {
        skip "in fine grained testing unless initial tests fail", 5
          unless !( $e_ok && $s_ok );
        my $uids = $ge->_accession_to_uids($accession);

        my @actual_uids = sort(@$uids);
        my @expected_uids = sort( 200016256, 100009115, 300409307 );
        is_deeply( \@actual_uids, \@expected_uids, "Get UIDs for accession" );

        my $sample_uids          = $ge->_find_sample_uid( \@expected_uids );
        my @actual_sample_uids   = sort(@$sample_uids);
        my @expected_sample_uids = (300409307);
        is_deeply( \@actual_sample_uids, \@expected_sample_uids,
            "Get UID for sample" );

        my $sra_uids          = $ge->_find_sra_uids( \@expected_sample_uids );
        my @actual_sra_uids   = sort(@$sra_uids);
        my @expected_sra_uids = (6495);
        is_deeply( \@actual_sra_uids, \@expected_sra_uids,
            "Get SRA UID for sample" );

        my ( $actual_experiment_type, $actual_sample ) =
          $ge->_get_sra_sample_and_experiment(@expected_sra_uids);
        is(
            $actual_experiment_type,
            'Histone H3K4me1',
            'Correct experiment type'
        );
        is_deeply( $actual_sample, $expected_sample,
            'Correct sample metadata' );
    }
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
        }
    );

    my $expected_raw_data = EpiRR::Model::RawData->new(
        archive         => 'GEO',
        primary_id      => $accession,
        experiment_type => '[HuEx-1_0-st] Affymetrix Human Exon 1.0 ST Array [probe set (exon) version]',
        archive_url =>
          'http://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSM706504',
    );

    my ( $raw_data, $sample ) = $ge->lookup_raw_data(
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
