#!/usr/bin/env perl
# cli-test.pl - black-box test suite for implementations command-line interfaces
use strict;
use warnings;
use utf8;
use Carp qw(croak);
use Readonly;
use Test::More;

# constants
Readonly::Scalar my $TZSOLAR_CLASS_PREFIX => "DateTime::TimeZone::Solar::";
Readonly::Scalar my $TZSOLAR_LON_ZONE_RE  => qr((Lon0[0-9][0-9][EW]) | (Lon1[0-7][0-9][EW]) | (Lon180[EW]))x;
Readonly::Scalar my $TZSOLAR_HOUR_ZONE_RE => qr((East|West)(0[0-9] | 1[0-2]))x;
Readonly::Scalar my $TZSOLAR_ZONE_RE      => qr( $TZSOLAR_LON_ZONE_RE | $TZSOLAR_HOUR_ZONE_RE )x;
Readonly::Scalar my $total_tests => 14 * 4;

# use CLI to get timezone names from longitude tz parameters
sub cli_tz_names
{
    # TODO
}

# check for valid timezone name for test to pass
sub is_valid_name
{
    # TODO
}

# run a single validity test
sub run_validity_test_lon
{
    my ( $progpath, $lon ) = @_;

    foreach my $use_lon_tz ( 0 .. 1 ) {
        my @params = ( progpath => $progpath, longitude => $lon, use_lon_tz => $use_lon_tz );
        my @tznames = cli_tz_names( @params );
        foreach my $name ( @tznames ) {
            ok( is_valid_name({ @params }, $name), "verified $name" );
        }
    }
    return;
}

# check the DateTime::TimeZone recognizes the Solar times zones as valid
sub run_validity_tests
{
    my $progpath = shift;

    foreach my $lon1 (qw( -180 -179.75 )) {
        run_validity_test_lon($progpath, $lon1);
    }
    for ( my $lon2 = -179 ; $lon2 <= 180 ; $lon2 += 30 ) {
        run_validity_test_lon($progpath, $lon2);
    }
    return;
}

#
# main
#

# read CLI parameters to locate program to test
if ( scalar @ARGV == 0 ){
    say STDERR "usage: $0 program-name";
    exit 1;
}
my $progpath = $ARGV[1];
if ( not -f $progpath ) {
    croak "file does not exist: $progpath"
}

# run tests
plan tests => $total_tests;
autoflush STDOUT 1;
run_validity_tests( $progpath );


