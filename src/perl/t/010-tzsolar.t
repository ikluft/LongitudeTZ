#!/usr/bin/env perl
# t/010-tzsolar.t - basic tests for TimeZone::Solar
#
# Copyright © 2022 Ian Kluft. This program is free software; you can
# redistribute it and/or modify it under the terms of the GNU General Public
# License Version 3. See  https://www.gnu.org/licenses/gpl-3.0-standalone.html

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2018);
## use critic (Modules::RequireExplicitPackage)

use utf8;
use Carp;
use Test::More;
use Readonly;
use TimeZone::Solar;

# constants
Readonly::Hash my %constants => (
    PRECISION_DIGITS       => 6,
    PRECISION_FP           => 0.0000005,
    MAX_DEGREES            => 360,
    MAX_LONGITUDE_INT      => 180,
    MAX_LONGITUDE_FP       => 180.0,
    MAX_LATITUDE_FP        => 90.0,
    POLAR_UTC_AREA         => 10,
    LIMIT_LATITUDE         => 80,
    MINUTES_PER_DEGREE_LON => 4,
);
Readonly::Scalar my $fp_epsilon => 2**-24;    # fp epsilon for fp_equal() based on 32-bit floats

# count tests
sub count_tests
{
    return ( ( scalar keys %constants ) + ( $constants{MAX_DEGREES} + 1 ) * 4 );
}

# floating point equality comparison utility function
# FP must not be compared with == operator - instead check if difference is within "machine epsilon" precision
sub fp_equal
{
    my ( $x, $y ) = @_;
    return ( abs( $x - $y ) < $fp_epsilon ) ? 1 : 0;
}

# check constants
sub test_constants
{
    foreach my $key ( sort keys %constants ) {
        if ( substr( $key, -3 ) eq "_FP" ) {

            # floating point value
            ok(
                fp_equal( TimeZone::Solar->_get_const($key), $constants{$key} ),
                sprintf( "constant check: %s = %.7f", $key, $constants{$key} )
            );
        } else {

            # other types
            is( TimeZone::Solar->_get_const($key), $constants{$key}, "constant check: $key = $constants{$key}" );
        }
    }
}

# compute expected time zone name and offset for test
# parameters use integer degrees and return the expected values at that longitude
# floating point variations on coordinates are up to the tests - but it expects this integer's result
sub expect_lon2tz
{
    my %params          = @_;
    my $lon             = $params{lon};
    my $use_lon_tz      = ( exists $params{use_lon_tz} and $params{use_lon_tz} );
    my $tz_degree_width = $use_lon_tz ? 1 : 15;                     # 1 for longitude-based tz, 15 for hour-based tz
    my $tz_max = $constants{MAX_LONGITUDE_INT} / $tz_degree_width;  # ±180 for longitude-based tz, ±12 for hour-based tz
    my $tz_type   = $use_lon_tz ? "Lon" : "Solar";
    my $tz_digits = $use_lon_tz ? 3     : 2;

    # generate time zone name and offset
    my ( $tz_name, $offset );
    if ( $lon > -$tz_degree_width / 2.0 and $lon < $tz_degree_width / 2.0 ) {

        # handle special case of tz centered on Prime Meridian (0° longitude)
        $tz_name = sprintf( "%s%s%0*d", $tz_type, "+", $tz_digits, 0 );
        $offset  = 0;
    } elsif ( $lon >= $tz_max - $tz_degree_width / 2 or $lon == -180 ) {

        # handle special case of half-wide tz at positive side of solar date line (180° longitude)
        # special case of -180: expect results for +180
        $tz_name = sprintf( "%s%s%0*d", $tz_type, "+", $tz_digits, $constants{MAX_LONGITUDE_INT} / $tz_degree_width );
        $offset  = 720;
    } elsif ( $lon <= -$tz_max + $tz_degree_width / 2 ) {

        # handle special case of half-wide tz at negative side of solar date line (180° longitude)
        $tz_name = sprintf( "%s%s%0*d", $tz_type, "-", $tz_digits, $constants{MAX_LONGITUDE_INT} / $tz_degree_width );
        $offset  = -720;
    } else {

        # handle other times zones
        $tz_name = sprintf( "%s%s%0*d",
            $tz_type,   $lon >= 0 ? "+" : "-",
            $tz_digits, int( abs( $lon / $tz_degree_width ) - 0.5 ) );
        $offset = int( $lon / $tz_degree_width - 0.5 ) * ( $constants{MINUTES_PER_DEGREE_LON} * $tz_degree_width );
    }

    #say STDERR "debug(lon:$lon,type:$tz_type) -> $tz_name, $offset";
    return ( $tz_name, $offset );
}

# perform tests for a degree of longitude
sub test_lon
{
    my $lon = shift;

    # hourly and longitude time zones without latitude
    foreach my $use_lon_tz ( 0, 1 ) {
        my $stz = TimeZone::Solar->new( longitude => $lon, use_lon_tz => $use_lon_tz );
        my ( $name, $offset ) = expect_lon2tz( lon => $lon, use_lon_tz => $use_lon_tz );
        is( $stz->name(),   $name,   sprintf( "%-04d lon: name = %s",   $lon, $name ) );
        is( $stz->offset(), $offset, sprintf( "%-04d lon: offset = %d", $lon, $offset ) );
    }
}

# check against every integer longitude value around the globe
sub test_global
{
    for ( my $lon = -180 ; $lon <= 180 ; $lon++ ) {
        test_lon($lon);
    }
}

# main
plan tests => count_tests();
test_constants();
test_global();
