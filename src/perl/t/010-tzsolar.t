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
use Test::Exception;
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
Readonly::Scalar my $debug_mode => (exists $ENV{TZSOLAR_TEST_DEBUG} and $ENV{TZSOLAR_TEST_DEBUG}) ? 1 : 0;
Readonly::Scalar my $fp_epsilon => 2**-24;    # fp epsilon for fp_equal() based on 32-bit floats
Readonly::Scalar my $total_constants => scalar keys %constants;
Readonly::Array my @test_point_longitudes => qw( 180.0 179.99999 -7.5 -7.49999 0.0 7.49999 7.5 -180.0 -179.99999 60.0 90.0 89.5 89.49999 120.0 );
Readonly::Array my @test_point_latitudes => qw( 80.0 79.99999 -80.0 -79.99999 );
Readonly::Array my @polar_test_points => ( gen_polar_test_points() );

# generate polar test points array
# used to generate @polar_test_points constant listed above
sub gen_polar_test_points
{
    my @polar_test_points;
    foreach my $use_lon_tz ( qw( 0 1 ) ) {
        foreach my $longitude ( @test_point_longitudes ) {
            foreach my $latitude ( @test_point_latitudes ) {
                push @polar_test_points, { longitude => $longitude, latitude => $latitude, use_lon_tz => $use_lon_tz };
            }
        }
    }
    return @polar_test_points;
}

# count tests
sub count_tests
{
    return (
        4                                       # in test_functions()
        + $total_constants                      # number of constants, in test_constants()
        + ( $constants{MAX_DEGREES} + 1 ) * 4   # per-degree tests from -180 to +180, in test_lon()
        + ( scalar @polar_test_points )         # in test_polar()
    );
}

# floating point equality comparison utility function
# FP must not be compared with == operator - instead check if difference is within "machine epsilon" precision
sub fp_equal
{
    my ( $x, $y ) = @_;
    return ( abs( $x - $y ) < $fp_epsilon ) ? 1 : 0;
}

# test TimeZone::Solar internal functions
sub test_functions
{
    # tests which throw exceptions
    throws_ok( sub { TimeZone::Solar::_class_guard() }, qr/invalid method call on undefined value/,
        "expected exception: _class_guard(undef)" );
    throws_ok( sub { TimeZone::Solar::_class_guard("UNIVERSAL") }, qr/invalid method call for 'UNIVERSAL':/,
        "expected exception: _class_guard(UNIVERSAL)" );

    # tests which should not throw exceptions
    my @constant_keys;
    lives_ok ( sub { @constant_keys = TimeZone::Solar->_get_const() }, "runs without exception: _get_const()" );
    is_deeply( \@constant_keys, [ sort keys %constants ], "list of constants matches" );
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
    my $lon             = $params{longitude};
    my $use_lon_tz      = ( exists $params{use_lon_tz} and $params{use_lon_tz} );
    my $tz_degree_width = $use_lon_tz ? 1 : 15;                     # 1 for longitude-based tz, 15 for hour-based tz
    my $tz_max = $constants{MAX_LONGITUDE_INT} / $tz_degree_width;  # ±180 for longitude-based tz, ±12 for hour-based tz
    my $tz_type   = $use_lon_tz ? "Lon" : "Solar";
    my $tz_digits = $use_lon_tz ? 3     : 2;
    my $precision = $constants{PRECISION_FP};

    # generate time zone name and offset
    my ( $tz_name, $offset );
    if ( abs( $lon ) < $tz_degree_width / 2.0 - $precision ) {

        # handle special case of tz centered on Prime Meridian (0° longitude)
        $tz_name = sprintf( "%s%s%0*d", $tz_type, "+", $tz_digits, 0 );
        $offset  = 0;
        $debug_mode and say STDERR "debug expect_lon2tz(): tz_name=$tz_name offset=$offset (case: prime meridian)";
    } elsif ( $lon >= $tz_max - $tz_degree_width / 2.0 - $precision or $lon <= -180.0 + $precision ) {

        # handle special case of half-wide tz at positive side of solar date line (180° longitude)
        # special case of -180: expect results for +180
        $tz_name = sprintf( "%s%s%0*d", $tz_type, "+", $tz_digits, $constants{MAX_LONGITUDE_INT} / $tz_degree_width );
        $offset  = 720;
        $debug_mode and say STDERR "debug expect_lon2tz(): tz_name=$tz_name offset=$offset (case: date line +)";
    } elsif ( $lon <= -$tz_max + $tz_degree_width / 2.0 + $precision ) {

        # handle special case of half-wide tz at negative side of solar date line (180° longitude)
        $tz_name = sprintf( "%s%s%0*d", $tz_type, "-", $tz_digits, $constants{MAX_LONGITUDE_INT} / $tz_degree_width );
        $offset  = -720;
        $debug_mode and say STDERR "debug expect_lon2tz(): tz_name=$tz_name offset=$offset (case: date line -)";
    } else {

        # handle other times zones
        my $tz_int = int( abs( $lon ) / $tz_degree_width + 0.5 + $precision );
        my $sign = ( $lon > -$tz_degree_width + $precision ) ? 1 : -1;
        $tz_name = sprintf( "%s%s%0*d", $tz_type,   $sign > 0 ? "+" : "-", $tz_digits, $tz_int );
        $offset = $sign * $tz_int * ( $constants{MINUTES_PER_DEGREE_LON} * $tz_degree_width );
        $debug_mode and say STDERR "debug expect_lon2tz(): tz_name=$tz_name offset=$offset (case: general)";
    }

    $debug_mode and say STDERR "debug(lon:$lon,type:$tz_type) -> $tz_name, $offset";
    return ( $tz_name, $offset );
}

# perform tests for a degree of longitude
sub test_lon
{
    my $lon = shift;

    # hourly and longitude time zones without latitude
    foreach my $use_lon_tz ( 0, 1 ) {
        my $stz = TimeZone::Solar->new( longitude => $lon, use_lon_tz => $use_lon_tz );
        my ( $name, $offset ) = expect_lon2tz( longitude => $lon, use_lon_tz => $use_lon_tz );
        is( $stz->name(),   $name,   sprintf( "%-04d lon: name = %s",   $lon, $name ) );
        is( $stz->offset(), $offset, sprintf( "%-04d lon: offset = %d", $lon, $offset ) );
    }
    return;
}

# check against every integer longitude value around the globe
sub test_global
{
    for ( my $lon = -180 ; $lon <= 180 ; $lon++ ) {
        test_lon($lon);
    }
    return;
}

# tests for polar latitudes - not needed at every degree of longitude
sub test_polar
{
    my $precision = $constants{PRECISION_FP};
    foreach my $test_point ( @polar_test_points ) {
        my $use_lon = ( abs( $test_point->{latitude} ) < $constants{LIMIT_LATITUDE} - $precision )
            ? $test_point->{longitude}
            : 0;
        my @result = expect_lon2tz( longitude => $use_lon, use_lon_tz => $test_point->{use_lon_tz} );
        my $test_name = "test point: "
            .sprintf( "longitude=%-10s latitude=%-9s use_lon_tz=%d",
                $test_point->{longitude}, $test_point->{latitude}, $test_point->{use_lon_tz} )
            ." => ("
            .join(" ", @result)
            .")";
        my $stz = TimeZone::Solar->new( %$test_point );
        is_deeply( [ $stz->name(), $stz->offset() ], \@result, $test_name );
    }
    return;
}

# main
plan tests => count_tests();
test_functions();
test_constants();
test_global();
test_polar();
