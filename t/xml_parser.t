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

use EpiRR::Parser::SRAXMLParser;

use Test::More;
use File::Basename;

use EpiRR::Model::RawData;
use EpiRR::Model::Sample;

my $p = EpiRR::Parser::SRAXMLParser->new();
{
    my $xml     = xml('SRX007379.xml');
    my $e = [];
    my @actual = $p->parse_experiment($xml,$e);

    my $expected = ['SRS004524','Histone H3K27me3','SRX007379',];
    
    is_deeply( \@actual, $expected, "Parse Experiment XML" );
    is_deeply($e,[],'No errors');
}
{
    my $xml = xml('SRX_duplicate.xml');
    my $e = [];
    $p->parse_experiment($xml,$e);

    is_deeply(
        $e,
        [
            "Found multiple samples in XML (SRS004524 and SRS004524)",
            "Found multiple experiment types in XML (Histone H3K27me3 and Histone H3K27me3)",
            "Found multiple experiments in XML (SRX007379 and SRX007379).",
        ],
        "Multiple experiments"
    );
}
{
    my $xml = xml('empty.xml');
    my $e = [];
    my $experiment = $p->parse_experiment($xml,$e);

    ok(!defined $experiment,"No experiment returned");

    is_deeply(
        $e,
        [
            "No experiment found",
            "No experiment_type found",
            "No sample found",
        ],
        "No experiments"
    );
}

{
    my $xml    = xml('SRS004524.xml');
    my $e = [];
    my $actual = $p->parse_sample($xml,$e);

    my $expected = EpiRR::Model::Sample->new(
        sample_id => 'SRS004524',
        meta_data => {
            MOLECULE               => 'genomic DNA',
            DISEASE                => 'none',
            BIOMATERIAL_PROVIDER   => 'Cellular Dynamics',
            BIOMATERIAL_TYPE       => 'Cell Line',
            LINE                   => 'H1',
            LINEAGE                => 'undifferentiated',
            DIFFERENTIATION_STAGE  => 'stage_zero',
            DIFFERENTIATION_METHOD => 'none',
            PASSAGE                => '42',
            MEDIUM                 => 'TESR',
            SEX                    => 'Unknown',
            'ENA-SPOT-COUNT'       => '23922417',
            'ENA-BASE-COUNT'       => '1537097042',
            'SPECIES'              => 'Homo sapiens',
        },
    );

    is_deeply( $actual, $expected, 'Parsed Sample' );
    is_deeply($e,[],'No sample errors');
}

{
    my $xml = xml('empty.xml');
    my $e = [];
    $p->parse_sample($xml,$e);

    is_deeply( $e, [ "Sample ID not found in XML", ], "No samples" );
}

{
    my $xml = xml('SRS_duplicate.xml');
    my $e = [];
    $p->parse_sample($xml,$e);

    is_deeply(
        $e,
        [ "Cannot handle multiple samples", ],
        "Multiple experiments"
    );
}

done_testing();

sub xml {
    my ($file)    = @_;
    my $dir       = dirname(__FILE__);
    my $file_path = $dir . '/xml/' . $file;

    open my $fh, '<', $file_path or fail("Could not open $file_path: $!");
    my $xml;
    {
        local $/;
        $xml = <$fh>;
    }
    close $fh;

    return $xml; 
}
