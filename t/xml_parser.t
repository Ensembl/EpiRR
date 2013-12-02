#!/usr/bin/env perl
use strict;
use warnings;

use EpiRR::Parser::SRAXMLParser;
use EpiRR::Model::RawData;

use Test::More;
use File::Basename;

use EpiRR::Model::RawData;
use EpiRR::Model::Sample;

{
    my $p      = parser('SRX007379.xml');
    my $actual = $p->parse_experiment();

    my $expected = EpiRR::Model::RawData->new(
        primary_id      => 'SRX007379',
        experiment_type => 'Histone H3K27me3',
        secondary_id    => 'SRS004524',
    );

    is_deeply( $actual, $expected, "Parse Experiment XML" );

}
{
    my $p = parser('SRX_duplicate.xml');
    $p->parse_experiment();

    is_deeply(
        $p->errors(),
        [
            "Cannot handle multiple samples",
            "Cannot handle multiple experiment_types",
            "Cannot handle multiple experiments"
        ],
        "Multiple experiments"
    );
}
{
    my $p = parser('empty.xml');
    $p->parse_experiment();

    is_deeply(
        $p->errors(),
        [
            "Experiment ID not found in XML",
            "Sample ID not found in XML",
            "Experiment type not found in XML",
        ],
        "No experiments"
    );
}

{
    my $p      = parser('SRS004524.xml');
    my $actual = $p->parse_sample();

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

    is_deeply( $actual, $expected, 'Parsed Sample' )
}

{
    my $p = parser('empty.xml');
    $p->parse_sample();

    is_deeply( $p->errors(), [ "Sample ID not found in XML", ], "No samples" );
}

done_testing();

sub parser {
    my ($file)    = @_;
    my $dir       = dirname(__FILE__);
    my $file_path = $dir . '/xml/' . $file;

    open my $fh, '<', $file_path or croak("Could not open $file_path: $!");
    my $xml;
    {
        local $/;
        $xml = <$fh>;
    }
    close $fh;

    return EpiRR::Parser::SRAXMLParser->new( xml => $xml );
}
