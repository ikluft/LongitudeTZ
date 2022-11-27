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

# constants
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

# enforce class access
sub _class_guard
{
    my $class = shift;
    my $classname = ref $class ? ref $class : $class;
    if ( not defined $classname ) {
        croak( "incompatible class: invalid method call on undefined value" );
    }
    if ( not $class->isa(__PACKAGE__) ) {
        croak( "incompatible class: invalid method call for '$classname': not in " . __PACKAGE__ . " hierarchy" );
    }
    return;
}

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
sub _init_latitude
{
    my $self  = shift;
    my $class = ref $self;

    # safety check on latitude
    if ( abs ( $self->{latitude} ) > $MAX_LATITUDE_FP + $PRECISION_FP ) {
        croak "$class: latitude when provided must be in range -90..+90";
    }

    # special case: use Solar+00 (equal to UTC) within 10° latitude of poles
    if ( abs( $self->{latitude} ) >= $LIMIT_LATITUDE - $PRECISION_FP ) {
        my $use_lon_tz = ( exists $self->{use_lon_tz} and $self->{use_lon_tz} );
        $self->name($use_lon_tz ? "Lon+000" : "Solar+00");
        $self->offset(0);
    }
    return;
}

# initialize - called by new()
sub init
{
    my $self  = shift;
    my $class = ref $self;
    if ( not exists $self->{longitude} ) {
        croak "$class: longitude parameter missing";
    }

    # if latitude is provided, use UTC within 10° latitude of poles
    if ( exists $self->{latitude} ) {

        # check latitude data and initialize special case for polar regions
        $self->_init_latitude();

        # return if initialized, otherwise fall through to set time zone from longitude as usual
        return if exists $self->{name} and exists $self->{offset};
    }

    #
    # set time zone from longitude
    #

    # safety check on longitude
    if (  abs( $self->{longitude} ) > $MAX_LONGITUDE_FP + $PRECISION_FP ) {
        croak "$class: longitude must be in range -180 to +180";
    }

    # set flag for longitude time zones: 0 = hourly 1-hour/15-degree zones, 1 = longitude 4-minute/1-degree zones
    # defaults to hourly time zone ($use_lon_tz=0)
    my $use_lon_tz      = ( exists $self->{use_lon_tz} and $self->{use_lon_tz} );
    my $tz_degree_width = $use_lon_tz ? 1 : 15;                     # 1 for longitude-based tz, 15 for hour-based tz
    my $tz_type         = $use_lon_tz ? "Lon" : "Solar";
    my $tz_digits       = $use_lon_tz ? 3     : 2;

    # handle special case of half-wide tz at positive side of solar date line (180° longitude)
    if ( $self->{longitude} >= $MAX_LONGITUDE_INT - $tz_degree_width / 2.0 - $PRECISION_FP
        or $self->{longitude} <= -$MAX_LONGITUDE_INT + $PRECISION_FP )
    {
        my $tz_name = sprintf "%s%s%0*d", $tz_type, "+", $tz_digits, $MAX_LONGITUDE_INT / $tz_degree_width;
        $self->name($tz_name);
        $self->offset(720);
        return;
    }

    # handle special case of half-wide tz at negativ< side of solar date line (180° longitude)
    if ( $self->{longitude} <= -$MAX_LONGITUDE_INT + $tz_degree_width / 2.0 + $PRECISION_FP ) {
        my $tz_name = sprintf "%s%s%0*d", $tz_type, "-", $tz_digits, $MAX_LONGITUDE_INT / $tz_degree_width;
        $self->name($tz_name);
        $self->offset(-720);
        return;
    }

    # handle other times zones
    my $tz_int = int( abs( $self->{longitude} ) / $tz_degree_width + 0.5 + $PRECISION_FP );
    my $sign = ( $self->{longitude} > -$tz_degree_width / 2.0 + $PRECISION_FP ) ? 1 : -1;
    my $tz_name = sprintf "%s%s%0*d", $tz_type, $sign > 0 ? "+" : "-", $tz_digits, $tz_int;
    my $offset = $sign * $tz_int * ( $MINUTES_PER_DEGREE_LON * $tz_degree_width );
    $self->name($tz_name);
    $self->offset($offset);
    return;
}

# instantiate a new TimeZone::Solar object
sub new
{
    my ( $in_class, @args ) = @_;
    my $class = ref($in_class) || $in_class;

    # safety check
    if ( not $class->isa(__PACKAGE__) ) {
        croak __PACKAGE__ . "->new() prohibited for unrelated class $class";
    }

    # instantiate object with @args data
    my $self = bless {@args}, $class;

    # use init() method of proper class, possibly a derived class
    if ( my $init_func = $self->can("init") ) {
        $init_func->($self);
    }
    return $self;
}

#
# accessor methods
#
sub longitude
{
    my @args = @_;
    my $self = $args[0];
    if ( scalar @args > 1 ) {
        $self->{longitude} = $args[1];
    }
    return $self->{longitude};
}

sub latitude
{
    my @args = @_;
    my $self = $args[0];
    if ( scalar @args > 1 ) {
        $self->{latitude} = $args[1];
    }
    return if not exists $self->{latitude};
    return $self->{latitude};
}

sub name
{
    my @args = @_;
    my $self = $args[0];
    if ( scalar @args > 1 ) {
        $self->{name} = $args[1];
    }
    return $self->{name};
}

sub offset
{
    my @args = @_;
    my $self = $args[0];
    if ( scalar @args > 1 ) {
        $self->{offset} = $args[1];
    }
    return $self->{offset};
}

#
# DateTime::TimeZone interface compatibility methods
# by definition, there is never a Daylight Savings change in the Solar time zones
#
sub has_dst_changes { return 0; }
sub is_floating { return 0; }
sub is_olson { return 0; }
sub category { return "Solar"; }
sub is_utc { my $self = shift; return $self->offset() == 0 ? 1 : 0; }
sub is_dst_for_datetime { return 0; }
sub offset_for_datetime { my $self = shift; return $self->offset(); }
sub offset_for_local_datetime { my $self = shift; return $self->offset(); }
# sub short_name_for_datetime { } # TODO

1;

__END__

=encoding utf8

=head1 SYNOPSIS

  use TimeZone::Solar;

  my $solar_tz1 = TimeZone::Solar->new(lat => $latiude, lon => $longitude);
  my $solar_tz2 = TimeZone::Solar->new(lon => $longitude); # assumes latitude between 80N and 80S
  my $tz_name = $solar_tz1->name();
  my $tz_offset = $solar_tz1->offset(); # minutes difference from GMT

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
