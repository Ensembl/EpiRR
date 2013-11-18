#!/usr/bin/env perl
use strict;
use warnings;

use EpiRR::Parser::TextFileParser;
use EpiRR::Model::RawData;

use Test::More;
use File::Basename;
use Data::Dumper;

#simple case where everything should work
{
    my $p = parser('file1.txt');
    $p->parse();
    my $ds1 = $p->dataset();

    is_deeply( $p->errors(), [], 'no errors' );
    ok( $ds1, 'have dataset 1' );
    is( $ds1->project(),        'THE_PROJECT', 'project match' )     if $ds1;
    is( $ds1->local_name(),     'TD1',         'local name match' )  if $ds1;
    is( $ds1->description(),    'test data',   'description match' ) if $ds1;
    is( $ds1->accession(),      'TP01',        'accession match' )   if $ds1;
    is( $ds1->raw_data_count(), 1,             'raw data count' )    if $ds1;
    my $rd1 = $ds1->get_raw_data(0);
    my $expected_rd = EpiRR::Model::RawData->new(archive => 'ABC', primary_id => 'FOO', secondary_id => 
    'Bar');
    
    ok( $rd1, 'have raw data 1' );
    is_deeply( $rd1,$expected_rd,'raw data as expected' ) if $rd1;
}

#unrecognised line type
{
  my $p = parser('file2.txt');
  $p->parse();
  is_deeply($p->errors,['Unknown line type - FAIL_ME at line 1'],'Expected error for bad line type');
}

#no project
{
  my $p = parser('file3.txt');
  $p->parse();
  is_deeply($p->errors,['No PROJECT given'],'No project specified')
}

#no raw data
{
  my $p = parser('file4.txt');
  $p->parse();
  is_deeply($p->errors,['No RAW_DATA given'],'No raw data specified')
}



done_testing();

sub parser {
    my ($file)    = @_;
    my $dir       = dirname(__FILE__);
    my $test_file = $dir . '/datasets/' . $file;

    return EpiRR::Parser::TextFileParser->new( file_path => $test_file );
}
