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

# solar time zone constants which must be in common among all programming language implementations
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
Readonly::Scalar my $MINUTES_PER_DEG_LON  => 4;                                 # minutes of time per degree longitude

# solar time zone black box testing constants
Readonly::Scalar my $TZDATA_REF_FILE        => $Bin . "/solar-tz.tab";            # tzdata reference file
Readonly::Array  my @SOLAR_TZ_FIELDS        => ( qw( longitude latitude name short_name long_name offset offset_min
    offset_sec is_utc ) );
Readonly::Array  my @SOLAR_TZ_ADHOC_TESTS   => ( qw( -180 -179.75 0 179.75 180 ) );
Readonly::Scalar my $SOLAR_TZ_DEG_STEP_SIZE => 90;
Readonly::Scalar my $SOLAR_TZ_TEST_SETS     => 360 / $SOLAR_TZ_DEG_STEP_SIZE + scalar( @SOLAR_TZ_ADHOC_TESTS );
Readonly::Scalar my $SOLAR_TZ_TESTS_PER_SET => 4 + scalar( @SOLAR_TZ_FIELDS) * 5;
Readonly::Scalar my $TZDATA_TESTS           => 3;
Readonly::Scalar my $TOTAL_TESTS            => $SOLAR_TZ_TEST_SETS * $SOLAR_TZ_TESTS_PER_SET * 2 + $TZDATA_TESTS;

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

# generate longitude-based tz data
sub gen_expect_tz_info_lon
{
    my $params_ref = shift;
    my $longitude  = $params_ref->{longitude};
    my $tz_degree_width = 1;

    # start on result
    my %expected;
    $expected{longitude} = $longitude;
    $expected{latitude} = $params_ref->{latitude} // "";

    # handle special cases at east/west sides of date line, or all other cases
    if (( $longitude >= $MAX_LONGITUDE_INT - $tz_degree_width / 2.0 - $PRECISION_FP )
        or ( $longitude <= -$MAX_LONGITUDE_INT + $PRECISION_FP ))
    {
        # special case: half-wide tz at positive side of solar date line (180° longitude)
        $expected{short_name} = "Lon180E";
        $expected{offset_min} = "720";
        $expected{is_utc} = "0";
    } elsif ( $longitude <= -$MAX_LONGITUDE_INT + $tz_degree_width / 2.0 + $PRECISION_FP ) {
        # special case: half-wide tz at negative side of solar date line (180° longitude)
        $expected{short_name} = "Lon180W";
        $expected{offset_min} = "-720";
        $expected{is_utc} = "0";
    } else {
        # all other cases
        my $tz_int = int( abs($longitude) / $tz_degree_width + 0.5 + $PRECISION_FP );
        my $sign   = ( $longitude > -$tz_degree_width / 2.0 + $PRECISION_FP ) ? 1 : -1;
        $expected{short_name} = sprintf( "Lon%03d%1s",
            int( abs( $longitude ) + 0.5 + $PRECISION_FP ), $longitude < 0 ? "W" : "E" );
        $expected{offset_min} = $sign * $tz_int * ( $MINUTES_PER_DEG_LON * $tz_degree_width );
        $expected{is_utc} = $expected{offset_min} == 0 ? "1" : "0";
    }

    $expected{name} = $expected{long_name} = "Solar/".$expected{short_name};
    $expected{offset_sec} = $expected{offset_min} * 60;
    {
        my $sign_str      = $expected{offset_min} >= 0 ? "+" : "-";
        my $hours         = int( abs($expected{offset_min}) / 60 );
        my $minutes       = abs($expected{offset_min}) % 60;
        $expected{offset} = sprintf "%s%02d%s%02d", $sign_str, $hours, ":", $minutes;
    }
    return \%expected;
}

# generate hour-based tz data
sub gen_expect_tz_info_hour
{
    my $params_ref = shift;
    my $longitude  = $params_ref->{longitude};
    my $tz_degree_width = 15;

    # start on result
    my %expected;
    $expected{longitude} = $longitude;
    $expected{latitude} = $params_ref->{latitude} // "";

    # handle special cases at east/west sides of date line, or all other cases
    if (( $longitude >= $MAX_LONGITUDE_INT - $tz_degree_width / 2.0 - $PRECISION_FP )
        or ( $longitude <= -$MAX_LONGITUDE_INT + $PRECISION_FP ))
    {
        # special case: half-wide tz at positive side of solar date line (180° longitude)
        $expected{short_name} = "East12";
        $expected{offset_min} = "720";
        $expected{is_utc} = "0";
    } elsif ( $longitude <= -$MAX_LONGITUDE_INT + $tz_degree_width / 2.0 + $PRECISION_FP ) {
        # special case: half-wide tz at negative side of solar date line (180° longitude)
        $expected{short_name} = "West12";
        $expected{offset_min} = "-720";
        $expected{is_utc} = "0";
    } else {
        # all other cases
        my $tz_int = int( abs($longitude) / $tz_degree_width + 0.5 + $PRECISION_FP );
        my $sign   = ( $longitude > -$tz_degree_width / 2.0 + $PRECISION_FP ) ? 1 : -1;
        $expected{short_name} = sprintf( "%4s%02d", $longitude < 0 ? "West" : "East",
            int( abs( $longitude ) / 15 + 0.5 + $PRECISION_FP ) );
        $expected{offset_min} = $sign * $tz_int * ( $MINUTES_PER_DEG_LON * $tz_degree_width );
        $expected{is_utc} = $expected{offset_min} == 0 ? "1" : "0";
    }

    $expected{name} = $expected{long_name} = "Solar/".$expected{short_name};
    $expected{offset_sec} = $expected{offset_min} * 60;
    {
        my $sign_str      = $expected{offset_min} >= 0 ? "+" : "-";
        my $hours         = int( abs($expected{offset_min}) / 60 );
        my $minutes       = abs($expected{offset_min}) % 60;
        $expected{offset} = sprintf "%s%02d%s%02d", $sign_str, $hours, ":", $minutes;
    }
    return \%expected;
}

# generate expected values for longitude tz data
sub gen_expect_tz_info
{
    my $params_ref = shift;
    my $use_lon_tz = $params_ref->{use_lon_tz} // 0;

    # process high latitudes
    if ( exists $params_ref->{latitude} ) {
        if ( abs( $params_ref->{latitude} ) >= $LIMIT_LATITUDE - $PRECISION_FP ) {
            my %expected;
            $expected{longitude} = $params_ref->{longitude};
            $expected{latitude} = $params_ref->{latitude};
            $expected{short_name} = $use_lon_tz ? "Lon000E" : "East00";
            $expected{name} = $expected{long_name} = "Solar/".$expected{short_name};
            $expected{offset} = "+00:00";
            $expected{offset_min} = "0";
            $expected{offset_sec} = "0";
            $expected{is_utc} = "1";
            return \%expected;
        }
    }

    if ($use_lon_tz) {

        # generate longitude-based tz expected info
        return gen_expect_tz_info_lon($params_ref);
    } else {

        # generate hour-based tz expected info
        return gen_expect_tz_info_hour($params_ref);
    }
}

# run external test program and capture output for each of 9 fields and 3 calling methods
sub run_prog_fields
{
    my $params_ref = shift;
    my $progpath   = $params_ref->{progpath};
    my $longitude  = $params_ref->{longitude};
    my $use_lon_tz = $params_ref->{use_lon_tz} // 0;
    my $type_str   = $use_lon_tz ? "longitude" : "hour";

    # start with empty results
    my %result = ( "run" => {}, "arg" => {}, "param" => {} );

    # run-per-field phase: separate runs for each field
    foreach my $field ( @SOLAR_TZ_FIELDS ) {

        # build command to run the program
        my @prog_cmd = ( $progpath, "--longitude=$longitude", "--type=$type_str", "--get=$field" );
        if ( $OSNAME eq "MSWin32" ) {
            unshift @prog_cmd, "perl";  # Windows can't use shebang hints, needs help finding interpreter
        }

        # run the program, capture stdout and stderr
        my ( $out, $err );
        my $res = IPC::Run::run \@prog_cmd, \undef, \$out, \$err, IPC::Run::timeout( 10 );
        chomp $out;

        # save result for this field's run
        $result{run}{$field} = {};
        $result{run}{$field}{res} = $res;
        $result{run}{$field}{data} = $out;
        $result{run}{$field}{err} = $err;
    }

    # arg-per-field phase: one run with separate --get arguments listing each field in order
    {
        # build command to run the program
        my @prog_cmd = ( $progpath, "--longitude=$longitude", "--type=$type_str" );
        foreach my $field ( @SOLAR_TZ_FIELDS ) {
            push @prog_cmd, "--get=$field";
        }
        if ( $OSNAME eq "MSWin32" ) {
            unshift @prog_cmd, "perl";  # Windows can't use shebang hints, needs help finding interpreter
        }

        # run the program, capture stdout and stderr
        my ( $out, $err );
        my $res = IPC::Run::run \@prog_cmd, \undef, \$out, \$err, IPC::Run::timeout( 10 );
        chomp $out;
        my @out_fields = split /^/xm, $out;
        foreach my $field ( @SOLAR_TZ_FIELDS ) {
            $result{arg}{$field} = {};
            $result{arg}{$field}{data} = shift @out_fields;
            chomp $result{arg}{$field}{data};
        }

        # save result for this phase's run
        $result{arg}{res} = $res;
        $result{arg}{err} = $err;
    }

    # param-per-field phase: one run with one --get argument with comma-delimited parameters for each field in order
    {
        # build command to run the program
        my @prog_cmd = ( $progpath, "--longitude=$longitude", "--type=$type_str",
            "--get=".join( ",", @SOLAR_TZ_FIELDS ) );
        if ( $OSNAME eq "MSWin32" ) {
            unshift @prog_cmd, "perl";  # Windows can't use shebang hints, needs help finding interpreter
        }

        # run the program, capture stdout and stderr
        my ( $out, $err );
        my $res = IPC::Run::run \@prog_cmd, \undef, \$out, \$err, IPC::Run::timeout( 10 );
        chomp $out;
        my @out_fields = split /^/xm, $out;
        foreach my $field ( @SOLAR_TZ_FIELDS ) {
            $result{param}{$field} = {};
            $result{param}{$field}{data} = shift @out_fields;
            chomp $result{param}{$field}{data};
        }

        # save result for this phase's run
        $result{param}{res} = $res;
        $result{param}{err} = $err;
    }
    return \%result;
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

# check for valid timezone vs expected infofor test to pass
sub test_valid_tz
{
    my ( $params_ref, $expected ) = @_;
    debug "testing for valid tz $expected ("
        . params_str( $params_ref ) . ")";

    # run CLI commands to generate tz info
    my $prog_result = run_prog_fields( $params_ref );

    # tests to verify against expected tz info

    # check data from run-per-field, arg-per-field and param-per-field phases
    # test counts:
    # * run-per-field: each run has error code, data and stderr: 9 * 3 = 27 tests
    # * arg-per-field & param-per-field:
    #   * one error code and stderr from the single run: 2 tests
    #   * each field has a data result: 9 tests
    foreach my $phase ( qw(run arg param) ) {
        # arg-per-field and param-per-field phases have one run result for the phase
        if ( $phase eq "arg" or $phase eq "param" ) {
            is( $prog_result->{$phase}{res}, 1, "prog $phase/".$expected->{short_name}
                ." (lon ".$params_ref->{longitude}."): expect success" );
            if ( not $prog_result->{$phase}{res} ) {
                debug "command failed for $phase/".$expected->{short_name};
            }
        }

        # loop through fields and test values
        foreach my $field ( @SOLAR_TZ_FIELDS ) {
            my $test_name = "$phase/".$expected->{short_name}."/$field";

            # run-per-field phase has a run result for every field
            if ( $phase eq "run" ) {
                is( $prog_result->{$phase}{$field}{res}, 1, "prog $test_name: expect success" );
                if ( not $prog_result->{$phase}{$field}{res} ) {
                    debug "command failed for $test_name";
                }
            }

            # test field data
            is( $prog_result->{$phase}{$field}{data}, $expected->{$field},
                "verify $test_name (lon ".$params_ref->{longitude}."): $field=".$expected->{$field} );
            if ( $prog_result->{$phase}{$field}{data} ne $expected->{$field}) {
                debug "failed $test_name (lon ".$params_ref->{longitude}.") - got "
                    .$prog_result->{$phase}{$field}{data}.", expected ".$expected->{$field};
            }

            # run-per-field phase has stderr result (expected empty) for every field
            if ( $phase eq "run" ) {
                is( $prog_result->{$phase}{$field}{err}, "", "stderr for $test_name (lon "
                    .$params_ref->{longitude}."): expect empty" );
                my $stderr = $prog_result->{$phase}{$field}{err} // "";
                if ( length $stderr > 0 ) {
                    say STDERR "error from $test_name: $stderr";
                }
            }
        }

        # arg-per-field and param-per-field phases have stderr result (expected empty) for the phase
        if ( $phase eq "arg" or $phase eq "param" ) {
            is( $prog_result->{$phase}{err}, "", "stderr for $phase/".$expected->{short_name}
                ." (lon ".$params_ref->{longitude}."): expect empty" );
            my $stderr = $prog_result->{$phase}{err} // "";
            if ( length $stderr > 0 ) {
                say STDERR "error from $phase/".$expected->{short_name}." command: $stderr";
            }
        }
    }

    return;
}

# run a single validity test
sub run_validity_test_lon
{
    my ( $progpath, $lon ) = @_;

    foreach my $use_lon_tz ( 0 .. 1 ) {
        my %params  = ( progpath => $progpath, longitude => $lon, use_lon_tz => $use_lon_tz );
        my $expected = gen_expect_tz_info( \%params );
        test_valid_tz( \%params, $expected );
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
    for ( my $lon2 = -179 ; $lon2 <= 180 ; $lon2 += $SOLAR_TZ_DEG_STEP_SIZE ) {
        run_validity_test_lon( $progpath, $lon2 );
    }
    return;
}

# check tzdata output against reference file
sub run_tzdata_test
{
    my $progpath = shift;
    my $ref_tzdata_text = File::Slurp::read_file( $TZDATA_REF_FILE );

    # run CLI command to generate tz info and verify against expected valid tz info
    my %params  = ( progpath => $progpath );
    my $prog_result = run_prog_tzdata( \%params );
    my $res_code    = $prog_result->{res};
    my $output      = $prog_result->{out};
    my $stderr      = $prog_result->{err};

    is( $res_code, 1, "tzdata command error code: expect success" );
    is( $output, $ref_tzdata_text, "tzdata output: expect reference file content" );
    is( $stderr, "", "tzdata stderr: expect empty" );
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
plan tests => $TOTAL_TESTS;
autoflush STDOUT 1;
run_validity_tests($progpath);
run_tzdata_test($progpath);
exit 0;
