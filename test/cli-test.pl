#!/usr/bin/env perl
# cli-test.pl - black-box test suite for implementations command-line interfaces
use strict;
use warnings;
use utf8;
use Carp qw(croak);
use English;
use Readonly;
use Getopt::Long;
use Test::More;
use IPC::Run;
use FindBin qw($Bin);
use File::Slurp;

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
Readonly::Scalar my $TZDATA_REF_FILE        => $Bin . "/solar-tz.tab";            # tzdata reference file
Readonly::Array  my @SOLAR_TZ_ADHOC_TESTS   => ( qw( -180 -179.75 0 179.75 180 ) );
Readonly::Scalar my $SOLAR_TZ_TEST_SETS     => 12 + scalar( @SOLAR_TZ_ADHOC_TESTS );
Readonly::Scalar my $SOLAR_TZ_TESTS_PER_SET => 2;
Readonly::Scalar my $TZDATA_TESTS           => 3;
Readonly::Scalar my $TOTAL_TESTS            => $SOLAR_TZ_TEST_SETS * $SOLAR_TZ_TESTS_PER_SET + $TZDATA_TESTS;

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
    my $tz_degree_width = 1;

    # special case: half-wide tz at positive side of solar date line (180° longitude)
    if (( $longitude >= $MAX_LONGITUDE_INT - $tz_degree_width / 2.0 - $PRECISION_FP )
        or ( $longitude <= -$MAX_LONGITUDE_INT + $PRECISION_FP ))
    {
        return "Lon180E";
    }

    # special case: half-wide tz at negative side of solar date line (180° longitude)
    if ( $longitude <= -$MAX_LONGITUDE_INT + $tz_degree_width / 2.0 + $PRECISION_FP ) {
        return "Lon180W";
    }

    # TODO
    return sprintf( "Lon%03d%1s", int( abs( $longitude ) + 0.5 + $PRECISION_FP ), $longitude < 0 ? "W" : "E" );
}

# generate hour-based tz name
sub cli_tz_name_hour
{
    my $params_ref = shift;
    my $longitude  = $params_ref->{longitude};
    my $tz_degree_width = 15;

    # special case: half-wide tz at positive side of solar date line (180° longitude)
    if (( $longitude >= $MAX_LONGITUDE_INT - $tz_degree_width / 2.0 - $PRECISION_FP )
        or ( $longitude <= -$MAX_LONGITUDE_INT + $PRECISION_FP ))
    {
        return "East12";
    }

    # special case: half-wide tz at negative side of solar date line (180° longitude)
    if ( $longitude <= -$MAX_LONGITUDE_INT + $tz_degree_width / 2.0 + $PRECISION_FP ) {
        return "West12";
    }

    # TODO
    return sprintf( "%4s%02d", $longitude < 0 ? "West" : "East", int( abs( $longitude ) / 15 + 0.5 + $PRECISION_FP ) );
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

# run external test program and capture output
sub run_prog
{
    my $params_ref = shift;
    my $progpath   = $params_ref->{progpath};
    my $longitude  = $params_ref->{longitude};
    my $use_lon_tz = $params_ref->{use_lon_tz} // 0;
    my $type_str   = $use_lon_tz ? "longitude" : "hour";

    # build command to run the program
    my @prog_cmd = ( $progpath, "--longitude=$longitude", "--type=$type_str", "--get=short_name" );
    if ( $OSNAME eq "MSWin32" ) {
        unshift @prog_cmd, "perl";  # Windows can't use shebang hints, needs help finding interpreter
    }

    # run the program, capture stdout and stderr
    my ( $out, $err );
    my $res = IPC::Run::run \@prog_cmd, \undef, \$out, \$err, IPC::Run::timeout( 10 );
    chomp $out;
    return { res => $res, out => $out, err => $err };
}

# run external test program and capture tzdata output
sub run_prog_tzdata
{
    my $params_ref = shift;
    my $progpath   = $params_ref->{progpath};

    # build command to run the program
    my @prog_cmd = ( $progpath, "--tzdata" );
    if ( $OSNAME eq "MSWin32" ) {
        unshift @prog_cmd, "perl";  # Windows can't use shebang hints, needs help finding interpreter
    }

    # run the program, capture stdout and stderr
    my ( $out, $err );
    my $res = IPC::Run::run \@prog_cmd, \undef, \$out, \$err, IPC::Run::timeout( 10 );
    return { res => $res, out => $out, err => $err };
}

# check for valid timezone name for test to pass
sub is_valid_name
{
    my ( $params_ref, $name ) = @_;
    debug "testing for valid name: $name ("
        . params_str( $params_ref ) . ")";

    # run CLI command to generate name and verify against expected valid name
    my $prog_result = run_prog( $params_ref );
    my $res_code    = $prog_result->{res};
    my $output      = $prog_result->{out};
    my $stderr      = $prog_result->{err};
    my $result      = ( $output eq $name );

    if ( length ( $stderr // "" ) > 0 ) {
        say STDERR "error from $name command: $stderr";
    }
    if ( not $res_code ) {
        debug "command run failed for $name test";
    }
    if ( not $result ) {
        debug "failed test - got $output, expected $name";
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
            ok( is_valid_name( \%params, $name ), "verified $name from $lon" );
        }
    }
    return;
}

# check the DateTime::TimeZone recognizes the Solar times zones as valid
sub run_validity_tests
{
    my $progpath = shift;

    foreach my $lon1 ( @SOLAR_TZ_ADHOC_TESTS ) {
        run_validity_test_lon( $progpath, $lon1 );
    }
    for ( my $lon2 = -179 ; $lon2 <= 180 ; $lon2 += 30 ) {
        run_validity_test_lon( $progpath, $lon2 );
    }
    return;
}

# check tzdata output against reference file
sub run_tzdata_test
{
    my $progpath = shift;
    my $ref_tzdata_text = File::Slurp::read_file( $TZDATA_REF_FILE );

    # run CLI command to generate name and verify against expected valid name
    my %params  = ( progpath => $progpath );
    my $prog_result = run_prog_tzdata( \%params );
    my $res_code    = $prog_result->{res};
    my $output      = $prog_result->{out};
    my $stderr      = $prog_result->{err};

    is( $res_code, 1, "tzdata command error code: expect success" );
    is( $output, $ref_tzdata_text, "tzdata output: expect reference file content" );
    is( $stderr, "", "tzdata stderr: expect empty" );
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
plan tests => $TOTAL_TESTS;
autoflush STDOUT 1;
run_validity_tests($progpath);
run_tzdata_test($progpath);
exit 0;
