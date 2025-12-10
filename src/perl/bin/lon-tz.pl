#!/usr/bin/env perl
# ABSTRACT: command-line interface for Perl implementation of LongitudeTZ library
# PODNAME: lon-tz.pl
# CREATED: 09/14/2020 as gen-ltz.pl, updated 2024-02-27 as lon-tz.pl
# part of Perl implementation of solar timezones library
#
# Copyright © 2020-2025 Ian Kluft. This program is free software; you can
# redistribute it and/or modify it under the terms of the GNU General Public
# License Version 3. See  https://www.gnu.org/licenses/gpl-3.0-standalone.html

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2015);
## use critic (Modules::RequireExplicitPackage)

use strict;
use warnings;
use utf8;
use autodie;
use feature qw(say);
use boolean;
use Config;
use Carp qw(croak);
use Getopt::Long;
use Try::Tiny;
use TimeZone::Solar;
use Readonly;
use File::Basename;

# constants
Readonly::Scalar my $progname => basename($0);

# debug flag
my $debug = false;

#
# tzdata file generation functions
#

# generate standard 1-hour-wide (15 degrees longitude) time zones
# input parameter: integer hours from GMT in the range
# These correspond to the GMT+x/GMT-x time zones, except with boundaries defined by longitude lines.
sub gen_hour_tz
{
    my $hour = int(shift);
    if ( $hour < -12 or $hour > 12 ) {
        croak "hour parameter must be -12 to +12 inclusive";
    }

    # Hours line up with time zones. So it's a equal to time zone offset.
    my $sign       = ( $hour >= 0 ) ? "+"    : "-";
    my $ew         = ( $hour >= 0 ) ? "East" : "West";
    my $offset_hr  = abs($hour);
    my $offset_min = 0;

    # generate strings from time zone parameters
    my $zone_abbrev = sprintf( "%s%02d",    $ew,     $offset_hr );
    my $zone_name   = sprintf( "%s/%s",     "Solar", $zone_abbrev );
    my $offset_str  = sprintf( "%s%d:%02d", $sign,   $offset_hr, $offset_min );

    # output time zone data
    say "# Solar Time by hourly increment: $offset_str";
    say "# " . join( "\t", qw(Zone NAME ), "", qw(STDOFF RULES FORMAT [UNTIL]) );
    say join( "\t", "Zone", $zone_name, $offset_str, "-", $zone_abbrev );
    say "";
    return;
}

# generate narrow solar time zone info
# input parameter: integer position in the range 48 to -48
# including one half degree either side of the meridian. Each time zone is named for its 1-degree-wide range.
# The exception is at the Solar Date Line, where +12 and -12 time zones are one half degree wide.
sub gen_narrow_tz
{
    my $tz_pos = int(shift);
    if ( $tz_pos < -48 or $tz_pos > 48 ) {
        croak "deg parameter must be -48 to +48 inclusive";
    }

    # use integer degrees to compute time zone parameters: longitude, east/west sign and minutes offset
    # $tz_pos>=0: positive degrees (east longitude), straightforward assignments of data
    # $tz_pos<0: negative degrees (west longitude)
    my $ew         = ( $tz_pos >= 0 ) ? "East" : "West";
    my $sign       = ( $tz_pos >= 0 ) ? ""     : "-";
    my $offset_hr  = abs( int( $tz_pos / 4 ) );
    my $offset_min = abs($tz_pos) % 4 * 15;

    # generate strings from time zone parameters
    my $zone_abbrev = sprintf( "%s%02d%02d", $ew,     $offset_hr, $offset_min );
    my $zone_name   = sprintf( "%s/%s",      "Solar", $zone_abbrev );
    my $offset_str  = sprintf( "%s%d:%02d",  $sign,   $offset_hr, $offset_min );

    # output time zone data
    say "# Solar Time by 15-minute increment: $offset_str";
    say "# " . join( "\t", qw(Zone NAME ), "", qw(STDOFF RULES FORMAT [UNTIL]) );
    say join( "\t", "Zone", $zone_name, $offset_str, "-", $zone_abbrev );
    say "";
    return;
}

# generate tzdata file
sub gen_tzfile
{
    # generate solar time zones in increments of 15 degrees of longitude (Easthh/Westhh)
    # standard 1-hour-wide time zones
    foreach my $hour ( -12 .. 12 ) {
        gen_hour_tz($hour);
    }

    # generate solar time zones in incrememnts of 15 minutes / 3.75 degrees of longitude (Easthhmm/Westhhmm)
    # narrow 15-minute-wide time zones
    foreach my $tz_pos ( -48 .. 48 ) {
        gen_narrow_tz($tz_pos);
    }
    return;
}

# do timezone operations requested from command line arguments
sub do_tz_op
{
    my ( $opts_ref, $obj ) = @_;

    my @fields;
    if ( exists $opts_ref->{get} ) {
        if ( ref $opts_ref->{get} eq "ARRAY" ) {
            @fields = split( /,/x, join( ',', @{ $opts_ref->{get} } ) );
        } else {
            croak "incorrect data type from --get parameter";
        }
    } else {
        @fields = qw(long_name);
    }

    # process requested fields
    foreach my $field (@fields) {
        try {
            say $obj->get($field);
        } catch {
            say ">>> undefined field $field";
        }
    }
    return;
}

#
# CLI mainline
#

# CLI-parsing mainline called from exception-catching wrapper
sub main
{
    my %opts;
    my $res =
        GetOptions( \%opts, 'debug', 'version|v', 'tzfile|tzdata', 'tzname:s', 'longitude:s', 'latitude:s', 'type:s',
        'get:s@', );

    # check validity of arguments
    if ( not $res ) {
        croak "CLI option processing failed";
    }

    # set debug flag if provided
    if ( $opts{debug} // false ) {
        $debug = true;
    }
    if ($debug) {
        my @out_opts;
        foreach my $key ( sort keys %opts ) {
            push @out_opts, "$key=" . $opts{$key};
        }
        say "opts: " . join( " ", @out_opts );
    }

    # display version
    if ( $opts{version} // 0 ) {
        say "version " . TimeZone::Solar->version() . " / Perl " . $Config{api_versionstring};
        exit 0;
    }

    # generate tzfile
    if ( $opts{tzfile} // 0 ) {
        gen_tzfile();
        exit 0;
    }

    # check mutually exclusive options
    if ( ( exists $opts{tzname} ) and ( exists $opts{longitude} ) ) {
        croak "mutually exclusive options tzname and longitude cannot be used at the same time";
    }

    # if tzname was provided, get parameters from it
    my $result;
    if ( exists $opts{tzname} ) {

        # verify class is defined, making time zone string valid
        my $classname = TimeZone::Solar::valid_tz_class( $opts{tzname} );
        if ( not defined $classname ) {
            croak "$opts{tzname} is not a valid solar/natural time zone name";
        }

        # run with the class name
        $result = do_tz_op( \%opts, $classname->new() );
    }

    # if longitude was provided (latitude optional), generate time zone parameters
    my $use_narrow = false;    # default to more common hour-based time zones rather than nice longitude-based tz
    if ( exists $opts{type} ) {
        if ( $opts{type} eq "hour" ) {
            $use_narrow = false;
        } elsif ( $opts{type} eq "longitude" ) {
            $use_narrow = true;
        } else {
            croak "unrecognized time zone type '" . $opts{type} . "'";
        }
    }
    if ( exists $opts{longitude} ) {
        if ( exists $opts{latitude} ) {
            $result = do_tz_op(
                \%opts,
                TimeZone::Solar->new(
                    longitude  => $opts{longitude},
                    latitude   => $opts{latitude},
                    use_narrow => $use_narrow
                )
            );
        } else {
            $result = do_tz_op(
                \%opts,
                TimeZone::Solar->new(
                    longitude  => $opts{longitude},
                    use_narrow => $use_narrow
                )
            );
        }
    }
    return;
}

# exception-catching wrapper
try {
    main();
} catch {

    # process any error/exception that we may have gotten
    my $ex = $_;

    # determine if there's an error message available to display
    if ( ref $ex ) {
        if ( my $ex_cap = Exception::Class->caught("WebFetch::Exception") ) {
            if ( $ex_cap->isa("WebFetch::TracedException") ) {
                warn $ex_cap->trace->as_string, "\n";
            }

            croak "$progname: " . $ex_cap->error . "\n";
        }
        if ( $ex->can("stringify") ) {

            # Error.pm, possibly others
            croak "$progname: " . $ex->stringify . "\n";
        } elsif ( $ex->can("as_string") ) {

            # generic - should work for many classes
            croak "$progname: " . $ex->as_string . "\n";
        } else {
            croak "$progname: unknown exception of type " . ( ref $ex ) . "\n";
        }
    } else {
        croak "pkg: $_\n";
    }
};

exit 0;

__END__

=encoding utf8

=head1 USAGE

    lon-tz.pl --version
    lon-tz.pl --tzfile > output-file
    lon-tz.pl [--longitude=nnn.nn] [--latitude=nnn.nn] fieldname [...]

=head1 OPTIONS


=head1 EXIT STATUS

The program returns the standard Unix exit codes of 0 for success and non-zero for errors.

=head1 LICENSE

TimeZone::Solar is Open Source software licensed under the GNU General Public License Version 3.
See L<https://www.gnu.org/licenses/gpl-3.0-standalone.html>.

=head1 BUGS AND LIMITATIONS

=cut
