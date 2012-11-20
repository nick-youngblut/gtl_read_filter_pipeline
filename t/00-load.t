#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'gtl_read_filter_pipeline' ) || print "Bail out!\n";
}

diag( "Testing gtl_read_filter_pipeline $gtl_read_filter_pipeline::VERSION, Perl $], $^X" );
