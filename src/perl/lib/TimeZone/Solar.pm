# TimeZone::Solar
# ABSTRACT: local solar timezone lookup and utilities
# part of Perl implementation of solar timezones library
#
# Copyright © 2020-2022 Ian Kluft. This program is free software; you can
# redistribute it and/or modify it under the terms of the GNU General Public
# License Version 3. See  https://www.gnu.org/licenses/gpl-3.0-standalone.html

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2018);
## use critic (Modules::RequireExplicitPackage)

package TimeZone::Solar;

use utf8;
use autodie;
use Carp qw(croak);
use Readonly;
use DateTime::TimeZone qw(0.80);
use Try::Tiny;

# constants
Readonly::Scalar my $debug_mode => (exists $ENV{TZSOLAR_DEBUG} and $ENV{TZSOLAR_DEBUG}) ? 1 : 0;
Readonly::Scalar my $TZSOLAR_CLASS_PREFIX => "DateTime::TimeZone::Solar::";
Readonly::Scalar my $TZSOLAR_LON_ZONE_RE   => qr((Lon0[0-9][0-9][EW]) | (Lon1[0-7][0-9][EW]) | (Lon180[EW]))x;
Readonly::Scalar my $TZSOLAR_HOUR_ZONE_RE   => qr((East|West)(0[0-9] | 1[0-2]))x;
Readonly::Scalar my $TZSOLAR_ZONE_RE   => qr( $TZSOLAR_LON_ZONE_RE | $TZSOLAR_HOUR_ZONE_RE )x;
Readonly::Scalar my $PRECISION_DIGITS  => 6;                                  # max decimal digits of precision
Readonly::Scalar my $PRECISION_FP      => ( 10**-$PRECISION_DIGITS ) / 2.0;   # 1/2 width of floating point equality
Readonly::Scalar my $MAX_DEGREES       => 360;                                # maximum degrees = 360
Readonly::Scalar my $MAX_LONGITUDE_INT => $MAX_DEGREES / 2;                   # min/max longitude in integer = 180
Readonly::Scalar my $MAX_LONGITUDE_FP  => $MAX_DEGREES / 2.0;                 # min/max longitude in float = 180.0
Readonly::Scalar my $MAX_LATITUDE_FP   => $MAX_DEGREES / 4.0;                 # min/max latitude in float = 90.0
Readonly::Scalar my $POLAR_UTC_AREA    => 10;                                 # latitude degrees around poles to use UTC
Readonly::Scalar my $LIMIT_LATITUDE    => $MAX_LATITUDE_FP - $POLAR_UTC_AREA; # max latitude for solar time zones
Readonly::Scalar my $MINUTES_PER_DEGREE_LON => 4;                             # minutes per degree longitude
Readonly::Hash my %constants => (                                             # allow tests to check constants
    PRECISION_DIGITS       => $PRECISION_DIGITS,
    PRECISION_FP           => $PRECISION_FP,
    MAX_DEGREES            => $MAX_DEGREES,
    MAX_LONGITUDE_INT      => $MAX_LONGITUDE_INT,
    MAX_LONGITUDE_FP       => $MAX_LONGITUDE_FP,
    MAX_LATITUDE_FP        => $MAX_LATITUDE_FP,
    POLAR_UTC_AREA         => $POLAR_UTC_AREA,
    LIMIT_LATITUDE         => $LIMIT_LATITUDE,
    MINUTES_PER_DEGREE_LON => $MINUTES_PER_DEGREE_LON,
);

# create timezone subclass
# this must be before the BEGIN block which uses it
sub _tz_subclass
{
    my $class = shift;

    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    my $class_check = 0;
    try {
        $class_check = eval "package $class { \@".$class."::ISA = qw(".__PACKAGE__.") }";
    };
    if ( not $class_check ) {
        croak __PACKAGE__."::_tz_subclass: unable to create class $class";
    }
    return;
}

# create subclasses for DateTime::TimeZone::Solar::* time zones
# Set subclass @ISA to point here as its parent. Then the subclass inherits methods from this class.
BEGIN {
    # duplicate constant within BEGIN scope because it runs before constant assignments
    Readonly::Scalar my $TZSOLAR_CLASS_PREFIX => "DateTime::TimeZone::Solar::";

    # hour-based timezones from -12 to +12
    foreach my $tz_dir ( qw( East West )) {
        foreach my $tz_int ( 0 .. 12 ) {
            my $short_name = sprintf ( "%s%02d", $tz_dir, $tz_int );
            my $long_name = "Solar/".$short_name;
            my $class_name = $TZSOLAR_CLASS_PREFIX.$short_name;
            _tz_subclass ( $class_name );
            $DateTime::TimeZone::Catalog::LINKS{$short_name} = $long_name;
        }
    }

    # longitude-based time zones from -180 to +180
    foreach my $tz_dir ( qw( E W )) {
        foreach my $tz_int ( 0 .. 180 ) {
            my $short_name = sprintf ( "Lon%03d%s", $tz_int, $tz_dir );
            my $long_name = "Solar/".$short_name;
            my $class_name = $TZSOLAR_CLASS_PREFIX.$short_name;
            _tz_subclass ( $class_name );
            $DateTime::TimeZone::Catalog::LINKS{$short_name} = $long_name;
        }
    }
}

# file globals
my %_INSTANCES;

# enforce class access
sub _class_guard
{
    my $class = shift;
    my $classname = ref $class ? ref $class : $class;
    if ( not defined $classname ) {
        croak( "incompatible class: invalid method call on undefined value" );
    }
    if ( not $class->isa( __PACKAGE__ )) {
        croak( "incompatible class: invalid method call for '$classname': not in " . __PACKAGE__ . " hierarchy" );
    }
    return;
}

# Override isa() method from UNIVERSAL to trick DateTime::TimeZone to accept our timezones as its subclasses.
# We don't inherit from DateTime::TimeZone as a base class because it's about Olson TZ db processing we don't need.
# But DateTime uses DateTime::TimeZone to look up time zones, and this makes solar timezones fit in.
## no critic ( Subroutines::ProhibitBuiltinHomonyms )
sub isa
{
    my ( $class, $type ) = @_;
    if ( $type eq "DateTime::TimeZone" ) {
        return 1;
    }
    return $class->SUPER::isa( $type );
}
## critic ( Subroutines::ProhibitBuiltinHomonyms )

# access constants - for use by tests
# if no name parameter is provided, return list of constant names
# throws exception if requested contant name doesn't exist
## no critic ( Subroutines::ProhibitUnusedPrivateSubroutines )
sub _get_const
{
    my @args = @_;
    my ( $class, $name ) = @args;
    _class_guard($class);

    # if no name provided, return list of keys
    if ( scalar @args <= 1 ) {
        return ( sort keys %constants );
    }

    # require valid name parameter
    if ( not exists $constants{$name} ) {
        croak "non-existent constant requested: $name";
    }
    return $constants{$name};
}
## critic ( Subroutines::ProhibitUnusedPrivateSubroutines )

# return TimeZone::Solar (or subclass) version number
sub version
{
    my $class = shift;
    _class_guard($class);

    {
        ## no critic (TestingAndDebugging::ProhibitNoStrict)
        no strict 'refs';
        if ( defined ${ $class . "::VERSION" } ) {
            return ${ $class . "::VERSION" };
        }
    }
    return "00-dev";
}

# check latitude data and initialize special case for polar regions - internal method called by init()
sub _tz_params_latitude
{
    my $param_ref = shift;

    # safety check on latitude
    if ( not $param_ref->{latitude} =~ /^[-+]?\d+(\.\d+)?$/x ) {
        croak(__PACKAGE__."::_tz_params_latitude: latitude '".$param_ref->{latitude}."' is not numeric")
    }
    if ( abs ( $param_ref->{latitude} ) > $MAX_LATITUDE_FP + $PRECISION_FP ) {
        croak __PACKAGE__."::_tz_params_latitude: latitude when provided must be in range -90..+90";
    }

    # special case: use Solar+00 (equal to UTC) within 10° latitude of poles
    if ( abs( $param_ref->{latitude} ) >= $LIMIT_LATITUDE - $PRECISION_FP ) {
        my $use_lon_tz = ( exists $param_ref->{use_lon_tz} and $param_ref->{use_lon_tz} );
        $param_ref->{short_name} = $use_lon_tz ? "Lon000E" : "East00";
        $param_ref->{name} = "Solar/".$param_ref->{short_name};
        $param_ref->{offset_min} = 0;
        $param_ref->{offset} = _offset_min2str(0);
        return $param_ref;
    }
    return;
}

# formatting functions
sub _tz_prefix
{
    my ( $use_lon_tz, $sign ) = @_;
    return $use_lon_tz ? "Lon" : ( $sign > 0 ? "East" : "West" );
}
sub _tz_suffix
{
    my ( $use_lon_tz, $sign ) = @_;
    return $use_lon_tz ? ( $sign > 0 ? "E" : "W" ) : ""
}

# get timezone parameters (name and minutes offset) - called by new()
sub _tz_params
{
    my %params = @_;
    if ( not exists $params{longitude} ) {
        croak __PACKAGE__."::_tz_params: longitude parameter missing";
    }

    # if latitude is provided, use UTC within 10° latitude of poles
    if ( exists $params{latitude} ) {

        # check latitude data and special case for polar regions
        my $lat_params = _tz_params_latitude(\%params);

        # return if initialized, otherwise fall through to set time zone from longitude as usual
        return $lat_params
            if ref $lat_params eq "HASH";
    }

    #
    # set time zone from longitude
    #

    # safety check on longitude
    if ( not $params{longitude} =~ /^[-+]?\d+(\.\d+)?$/x ) {
        croak(__PACKAGE__."::_tz_params: longitude '".$params{longitude}."' is not numeric")
    }
    if ( abs( $params{longitude} ) > $MAX_LONGITUDE_FP + $PRECISION_FP ) {
        croak __PACKAGE__."::_tz_params: longitude must be in the range -180 to +180";
    }

    # set flag for longitude time zones: 0 = hourly 1-hour/15-degree zones, 1 = longitude 4-minute/1-degree zones
    # defaults to hourly time zone ($use_lon_tz=0)
    my $use_lon_tz      = ( exists $params{use_lon_tz} and $params{use_lon_tz} );
    my $tz_degree_width = $use_lon_tz ? 1 : 15;                     # 1 for longitude-based tz, 15 for hour-based tz
    my $tz_digits       = $use_lon_tz ? 3     : 2;

    # handle special case of half-wide tz at positive side of solar date line (180° longitude)
    if ( $params{longitude} >= $MAX_LONGITUDE_INT - $tz_degree_width / 2.0 - $PRECISION_FP
        or $params{longitude} <= -$MAX_LONGITUDE_INT + $PRECISION_FP )
    {
        my $tz_name = sprintf "%s%0*d%s",
            _tz_prefix( $use_lon_tz, 1 ),
            $tz_digits, $MAX_LONGITUDE_INT / $tz_degree_width,
            _tz_suffix( $use_lon_tz, 1 );
        $params{short_name} = $tz_name;
        $params{name} = "Solar/".$tz_name;
        $params{offset_min} = 720;
        $params{offset} = _offset_min2str( 720 );
        return \%params;
    }

    # handle special case of half-wide tz at negativ< side of solar date line (180° longitude)
    if ( $params{longitude} <= -$MAX_LONGITUDE_INT + $tz_degree_width / 2.0 + $PRECISION_FP ) {
        my $tz_name = sprintf "%s%0*d%s",
            _tz_prefix( $use_lon_tz, -1 ),
            $tz_digits, $MAX_LONGITUDE_INT / $tz_degree_width,
            _tz_suffix( $use_lon_tz, -1 );
        $params{short_name} = $tz_name;
        $params{name} = "Solar/".$tz_name;
        $params{offset_min} = -720;
        $params{offset} = _offset_min2str( -720 );
        return \%params;
    }

    # handle other times zones
    my $tz_int = int( abs( $params{longitude} ) / $tz_degree_width + 0.5 + $PRECISION_FP );
    my $sign = ( $params{longitude} > -$tz_degree_width / 2.0 + $PRECISION_FP ) ? 1 : -1;
    my $tz_name = sprintf "%s%0*d%s",
        _tz_prefix( $use_lon_tz, $sign ),
        $tz_digits, $tz_int,
        _tz_suffix( $use_lon_tz, $sign );
    my $offset = $sign * $tz_int * ( $MINUTES_PER_DEGREE_LON * $tz_degree_width );
    $params{short_name} = $tz_name;
    $params{name} = "Solar/".$tz_name;
    $params{offset_min} = $offset;
    $params{offset} = _offset_min2str( $offset );
    return \%params;
}

# get timezone instance
sub _tz_instance
{
    my $hashref = shift;

    # consistency checks
    if ( not defined $hashref ) {
        croak __PACKAGE__."::_tz_instance: object not found in parameters";
    }
    if ( ref $hashref ne "HASH" ) {
        croak __PACKAGE__."::_tz_instance: received non-hash ".(ref $hashref)." for object";
    }
    if ( not exists $hashref->{short_name}) {
        croak __PACKAGE__."::_tz_instance: name attribute missing";
    }
    if ( $hashref->{short_name} !~ $TZSOLAR_ZONE_RE ) {
        croak __PACKAGE__."::_tz_instance: name attrbute ".$hashref->{short_name}." is not a valid Solar timezone";
    }

    # look up class instance, return it if found
    my $class = $TZSOLAR_CLASS_PREFIX.$hashref->{short_name};
    if ( exists $_INSTANCES{$class}) {
        # forward lat/lon parameters to the existing instance, mainly so tests can see where it came from
        foreach my $key ( qw(longitude latitude) ) {
            if (exists $hashref->{$key}) {
                $_INSTANCES{$class}->{$key} = $hashref->{$key};
            } else {
                delete $_INSTANCES{$class}->{$key};
            }
        }
        return $_INSTANCES{$class};
    }

    # make sure the new singleton object's class is a subclass of TimeZone::Solar
    # this should have already been done by the BEGIN block for all solar timezone subclasses
    if ( not $class->isa( __PACKAGE__ )) {
        _tz_subclass( $class );
    }


    # bless the new object into the timezone subclass and save the singleton instance
    my $obj = bless $hashref, $class;
    $_INSTANCES{$class} = $obj;

    # return the new object
    return $obj;
}

# instantiate a new TimeZone::Solar object
sub new
{
    my ( $in_class, %args ) = @_;
    my $class = ref($in_class) || $in_class;

    # safety check
    if ( not $class->isa(__PACKAGE__) ) {
        croak __PACKAGE__ . "->new() prohibited for unrelated class $class";
    }

    # if we got here via DataTime::TimeZone::Solar::*->new(), override longitude/use_lon_tz parameters from class name
    if ( $in_class =~ qr( $TZSOLAR_CLASS_PREFIX ( $TZSOLAR_ZONE_RE ))x ) {
        my $in_tz = $1;
        if ( substr( $in_tz, 0, 4 ) eq "East" ) {
            my $tz_int = int substr( $in_tz, 4, 2 );
            $args{longitude} = $tz_int * 15;
            $args{use_lon_tz} = 0;
        } elsif ( substr( $in_tz, 0, 4 ) eq "West" ) {
            my $tz_int = int substr( $in_tz, 4, 2 );
            $args{longitude} = -$tz_int * 15;
            $args{use_lon_tz} = 0;
        } elsif (  substr( $in_tz, 0, 3 ) eq "Lon" ) {
            my $tz_int = int substr( $in_tz, 3, 3 );
            my $sign = ( substr( $in_tz, 6, 1 ) eq "E" ? 1 : -1 );
            $args{longitude} = $sign * $tz_int;
            $args{use_lon_tz} = 1;
        } else {
            croak __PACKAGE__ . "->new() received unrecognized class name $in_class";
        }
        delete $args{latitude};
    }

    # use %args to look up a timezone singleton instance
    # make a new one if it doesn't yet exist
    my $tz_params = _tz_params( %args );
    my $self = _tz_instance( $tz_params );

    # use init() method, with support for derived classes that may override it
    if ( my $init_func = $self->can("init") ) {
        $init_func->($self);
    }
    return $self;
}

#
# accessor methods
#

# longitude: read-only accessor
sub longitude
{
    my $self = shift;
    return $self->{longitude};
}

# latitude read-only accessor
sub latitude
{
    my $self = shift;
    return if not exists $self->{latitude};
    return $self->{latitude};
}

# name: read/write accessor
sub name
{
    my @args = @_;
    my $self = $args[0];
    if ( scalar @args > 1 ) {
        $self->{name} = $args[1];
    }
    return $self->{name};
}

# short_name: read/write accessor
sub short_name
{
    my @args = @_;
    my $self = $args[0];
    if ( scalar @args > 1 ) {
        $self->{short_name} = $args[1];
    }
    return $self->{short_name};
}

# long_name: read accessor
sub long_name { my $self = shift; return $self->name(); }

# offset read accessor
sub offset
{
    my $self = shift;
    return $self->{offset};
}

# offset_min read accessor
sub offset_min
{
    my $self = shift;
    return $self->{offset_min};
}


#
# conversion functions
#

# convert offset minutes to string
sub _offset_min2str
{
    my $offset_min = shift;
    my $sign = $offset_min >= 0 ? "+" : "-";
    my $hours = int( abs($offset_min) / 60 );
    my $minutes = abs($offset_min) % 60;
    return sprintf "%s%02d%s%02d", $sign, $hours, ":", $minutes;
}

# offset minutes as string from
sub offset_str
{
    my $self = shift;
    return $self->{offset};
}

# convert offset minutes to seconds
sub offset_sec
{
    my $self = shift;
    return $self->{offset_min} * 60;
}

#
# DateTime::TimeZone interface compatibility methods
# By definition, there is never a Daylight Savings change in the Solar time zones.
#
sub spans { return []; }
sub has_dst_changes { return 0; }
sub is_floating { return 0; }
sub is_olson { return 0; }
sub category { return "Solar"; }
sub is_utc { my $self = shift; return $self->{offset_min} == 0 ? 1 : 0; }
sub is_dst_for_datetime { return 0; }
sub offset_for_datetime { my $self = shift; return $self->offset_sec(); }
sub offset_for_local_datetime { my $self = shift; return $self->offset_sec(); }
sub short_name_for_datetime {my $self = shift; return $self->short_name(); }

# instance method to respond to DateTime::TimeZone
sub instance
{
    my ( $class, %args ) = @_;
    _class_guard($class);
    delete $args{is_olson};
    return $class->new(%args);
}

1;

__END__

=encoding utf8

=head1 SYNOPSIS

  use TimeZone::Solar;

  my $solar_tz1 = TimeZone::Solar->new(lat => $latiude, lon => $longitude);
  my $solar_tz2 = TimeZone::Solar->new(lon => $longitude); # assumes latitude between 80N and 80S
  my $tz_name = $solar_tz1->name();                        # long name 'Solar/xxxxxx'
  my $tz_short_name = $solar_tz1->short_name();            # short name without 'Solar/'
  my $tz_offset = $solar_tz1->offset();                    # difference from GMT as string: +nn:nn or -nn:nn
  my $tz_offset = $solar_tz1->offset_min();                # difference from GMT in minutes

=head1 DESCRIPTION

=head1 FUNCTIONS AND METHODS

=over 1

=item TimeZone::Solar->version()

Return the version number of TimeZone::Solar, or for any subclass which inherits the method.

When running code within a source-code development workspace, it returns "00-dev" to avoid warnings
about undefined values.
Release version numbers are assigned and added by the build system upon release,
and are not available when running directly from a source code repository.

=back

=head1 LICENSE

TimeZone::Solar is Open Source software licensed under the GNU General Public License Version 3.
See L<https://www.gnu.org/licenses/gpl-3.0-standalone.html>.

=head1 BUGS AND LIMITATIONS

=cut
