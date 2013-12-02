#!/usr/bin/env perl
use strict;
use warnings;

use EpiRR::Parser::SRAXMLParser;
use EpiRR::Model::RawData;

use Test::More;
use File::Basename;

use EpiRR::Model::RawData;
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
