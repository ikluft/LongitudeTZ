#!/usr/bin/env perl
# cli-test.pl - black-box test suite for implementations command-line interfaces
use strict;
use warnings;
use utf8;
use Carp qw(croak);
use Readonly;
use Getopt::Long;
use Test::More;

# constants
Readonly::Scalar my $TZSOLAR_CLASS_PREFIX => "DateTime::TimeZone::Solar::";
Readonly::Scalar my $TZSOLAR_LON_ZONE_RE  => qr((Lon0[0-9][0-9][EW]) | (Lon1[0-7][0-9][EW]) | (Lon180[EW]))x;
Readonly::Scalar my $TZSOLAR_HOUR_ZONE_RE => qr((East|West)(0[0-9] | 1[0-2]))x;
Readonly::Scalar my $TZSOLAR_ZONE_RE      => qr( $TZSOLAR_LON_ZONE_RE | $TZSOLAR_HOUR_ZONE_RE )x;
Readonly::Scalar my $PRECISION_DIGITS     => 6;                                   # max decimal digits of precision
Readonly::Scalar my $PRECISION_FP         => ( 10**-$PRECISION_DIGITS ) / 2.0;    # 1/2 width of floating point equality
Readonly::Scalar my $MAX_DEGREES          => 360;                                 # maximum degrees = 360
Readonly::Scalar my $MAX_LONGITUDE_INT    => $MAX_DEGREES / 2;                    # min/max longitude in integer = 180
Readonly::Scalar my $MAX_LONGITUDE_FP     => $MAX_DEGREES / 2.0;                  # min/max longitude in float = 180.0
Readonly::Scalar my $MAX_LATITUDE_FP      => $MAX_DEGREES / 4.0;                  # min/max latitude in float = 90.0
Readonly::Scalar my $POLAR_UTC_AREA       => 10;                                  # latitude near poles to use UTC
Readonly::Scalar my $LIMIT_LATITUDE       => $MAX_LATITUDE_FP - $POLAR_UTC_AREA;  # max latitude for solar time zones
Readonly::Scalar my $MINUTES_PER_DEGREE_LON => 4;                                 # minutes per degree longitude
Readonly::Scalar my $total_tests            => 14 * 2;

# globals
my $debug = 0;

# print debugging statements if debugging is enabled
sub debug
{
    my @values = @_;
    if ( $debug ) {
        say STDERR "debug: ".join( "", @values );
    }
    return;
}

# build string of parameter keys & values for debugging
sub params_str
{
    my $params_ref = shift;
    my @result;
    foreach my $key ( sort keys %$params_ref ) {
        push @result, "$key=" . $params_ref->{$key};
    }
    return join ", ", @result;
}

# generate longitude-based tz name
sub cli_tz_name_lon
{
    my $params_ref = shift;
    my $longitude  = $params_ref->{longitude};

    # TODO
    return sprintf( "Lon%03d%1s", abs( int($longitude) ), $longitude < 0 ? "W" : "E", );
}

# generate hour-based tz name
sub cli_tz_name_hour
{
    my $params_ref = shift;
    my $longitude  = $params_ref->{longitude};

    # TODO
    return sprintf( "%4s%02d", $longitude < 0 ? "West" : "East", abs( int( ( $longitude + 0.5 ) / 15 ) ) );
}

# use CLI to get timezone name from longitude tz parameters
sub cli_tz_name
{
    my $params_ref = shift;
    my $use_lon_tz = $params_ref->{use_lon_tz} // 0;

    # process high latitudes
    if ( exists $params_ref->{latitude} ) {
        if ( abs( $params_ref->{latitude} ) >= $LIMIT_LATITUDE - $PRECISION_FP ) {
            return $use_lon_tz ? "Lon000E" : "East00";
        }
    }

    if ($use_lon_tz) {

        # generate longitude-based tz name
        return cli_tz_name_lon($params_ref);
    } else {

        # generate hour-based tz name
        return cli_tz_name_hour($params_ref);
    }
}

# check for valid timezone name for test to pass
sub is_valid_name
{
    my ( $params_ref, $name ) = @_;
    debug "testing for valid name: $name ("
        . params_str( $params_ref ) . ")";

    # run CLI command to generate name and verify against expected valid name
    my $progpath   = $params_ref->{progpath};
    my $longitude  = $params_ref->{longitude};
    my $use_lon_tz = $params_ref->{use_lon_tz} // 0;
    my $type_str   = $use_lon_tz ? "longitude" : "hour";
    my $output     = qx($progpath --longitude=$longitude --type=$type_str --get=short_name);
    chomp $output;
    my $result = ( $output eq $name );

    if ( not $result ) {
        debug "failed to match $output vs $name";
    }
    return $result;
}

# run a single validity test
sub run_validity_test_lon
{
    my ( $progpath, $lon ) = @_;

    foreach my $use_lon_tz ( 0 .. 1 ) {
        my %params  = ( progpath => $progpath, longitude => $lon, use_lon_tz => $use_lon_tz );
        my @tznames = cli_tz_name( \%params );
        foreach my $name (@tznames) {
            ok( is_valid_name( \%params, $name ), "verified $name" );
        }
    }
    return;
}

# check the DateTime::TimeZone recognizes the Solar times zones as valid
sub run_validity_tests
{
    my $progpath = shift;

    foreach my $lon1 (qw( -180 -179.75 )) {
        run_validity_test_lon( $progpath, $lon1 );
    }
    for ( my $lon2 = -179 ; $lon2 <= 180 ; $lon2 += 30 ) {
        run_validity_test_lon( $progpath, $lon2 );
    }
    return;
}

#
# main
#

# read CLI parameters to locate program to test
GetOptions ( "debug" => \$debug );
if ( scalar @ARGV == 0 ) {
    say STDERR "usage: $0 program-name";
    exit 1;
}
my $progpath = $ARGV[0];
if ( not -f $progpath ) {
    croak "file does not exist: $progpath";
}

# run tests
plan tests => $total_tests;
autoflush STDOUT 1;
run_validity_tests($progpath);
