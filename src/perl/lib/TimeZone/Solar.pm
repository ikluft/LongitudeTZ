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
use Modern::Perl qw(2017);
## use critic (Modules::RequireExplicitPackage)

package TimeZone::Solar;
use utf8;
use autodie;
use Carp qw(croak);
use Readonly;

# constants
Readonly::Scalar my $PRECISION_DIGITS => 6;                                 # max decimal digits of precision
Readonly::Scalar my $FP_PRECISION => (10 ** -$PRECISION_DIGITS) / 2.0;      # 1/2 width of floating point equality
Readonly::Scalar my $MAX_DEGREES => 360;                                    # maximum degrees = 360
Readonly::Scalar my $MAX_LONGITUDE_INT => $MAX_DEGREES / 2;                 # min/max longitude in integer = 180
Readonly::Scalar my $MAX_LONGITUDE_FP => $MAX_DEGREES / 2.0;                # min/max longitude in float = 180.0
Readonly::Scalar my $MAX_LATITUDE_FP => $MAX_DEGREES / 4.0;                 # min/max latitude in float = 90.0
Readonly::Scalar my $POLAR_UTC_AREA => 10.0;                                # latitude degrees around poles to use UTC
Readonly::Scalar my $LIMIT_LATITUDE => $MAX_LATITUDE_FP - $POLAR_UTC_AREA;  # max latitude for solar time zones
Readonly::Scalar my $MINUTES_PER_DEGREE_LON => 4;                           # minutes per degree longitude

# initialize - called by new()
sub init
{
    my $self = shift;
    my $class = ref $self;
    if ( not exists $self->{longitude}) {
        croak "$class: longitude parameter missing";
    }

    # if latitude is provided, use UTC within 10° latitude of poles
    if ( exists $self->{latitude}) {
        # safety check on latitude
        if ( $self->{latitude} > $MAX_LATITUDE_FP or $self->{latitude} < -$MAX_LATITUDE_FP ) {
            croak "$class: latitude when provided must be in range -90..+90";
        }

        # special case: use Solar+00 (equal to UTC) within 10° latitude of poles
        if ( $self->{latitude} >= $LIMIT_LATITUDE or $self->{latitude} <= -$LIMIT_LATITUDE ) {
            $self->name( "Solar+00" );
            $self->offset( 0 );
        }

        # otherwise fall through to set time zone from longitude as usual
    }

    #
    # set time zone from longitude
    #

    # safety check on longitude
    if ( $self->{longitude} > $MAX_LONGITUDE_FP or $self->{longitude} < -$MAX_LONGITUDE_FP ) {
        croak "$class: longitude must be in range -180 to +180";
    }

    # floating point equality test for solar date line: flip sign positive if within precision margin of the line
    if ( $self->{longitude} < -$MAX_LONGITUDE_FP + $FP_PRECISION ) {
        $self->{longitude} = -$self->{longitude};
    }

    # set flag for longitude time zones: 0 = hourly 1-hour/15-degree zones, 1 = longitude 4-minute/1-degree zones
    # defaults to hourly time zone ($use_lon_tz=0)
    my $use_lon_tz = ( exists $self->{use_lon_tz} and $self->{use_lon_tz});
    my $tz_degree_width = $use_lon_tz ? 1 : 15; # 1 for longitude-based tz, 15 for hour-based tz
    my $tz_max = $MAX_LONGITUDE_INT / $tz_degree_width; # ±180 for longitude-based tz, ±12 for hour-based tz

    # handle special case of tz centered on Prime Meridian (0° longitude)
    if ( $self->{longitude} > -$tz_degree_width/2.0 and $self->{longitude} < $tz_degree_width/2.0 ) {
        my $tz_name = sprintf "%s%s%0*d", $use_lon_tz ? "Lon" : "Solar", "+", $use_lon_tz ? 3 : 2, 0;
        $self->name( $tz_name );
        $self->offset( 0 );
        return;
    }

    # handle special case of half-wide tz at positive side of solar date line (180° longitude)
    if ( $self->{longitude} >= $tz_max - $tz_degree_width/2 - $FP_PRECISION ) {
        my $tz_name = sprintf "%s%s%0*d", $use_lon_tz ? "Lon" : "Solar", "+", $use_lon_tz ? 3 : 2,
            $MAX_LONGITUDE_INT / $tz_degree_width;
        $self->name( $tz_name );
        $self->offset( 720 );
        return;
    }

    # handle special case of half-wide tz at negativ< side of solar date line (180° longitude)
    if ( $self->{longitude} >= -$tz_max + $tz_degree_width/2 + $FP_PRECISION ) {
        my $tz_name = sprintf "%s%s%0*d", $use_lon_tz ? "Lon" : "Solar", "-", $use_lon_tz ? 3 : 2,
            $MAX_LONGITUDE_INT / $tz_degree_width;
        $self->name( $tz_name );
        $self->offset( -720 );
        return;
    }

    # handle other times zones
    my $tz_name = sprintf "%s%s%0*d", $use_lon_tz ? "Lon" : "Solar", $self->{longitude} >= 0 ? "+" : "-",
        $use_lon_tz ? 3 : 2, int( abs( $self->{longitude} / $tz_degree_width ) - 0.5 );
        my $offset = int( $self->{longitude} / $tz_degree_width - 0.5 )
            * ( $MINUTES_PER_DEGREE_LON * $tz_degree_width);
    $self->name( $tz_name );
    $self->offset( $offset );
    return;
}

# instantiate a new TimeZone::Solar object
sub new {
    my ( $in_class, @args ) = @_;
    my $class = ref($in_class) || $in_class;

    # safety check
    if ( not $class->isa(__PACKAGE__)) {
        croak __PACKAGE__."->new() prohibited for unrelated class $class";
    }

    # instantiate object with @args data
    my $self = bless { @args }, $class;

    # use init() method of proper class, possibly a derived class
    if ( my $init_func = $self->can("init")) {
        $init_func->( $self );
    }
    return $self;
}

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

=head1 LICENSE

TimeZone::Solar is Open Source software licensed under the GNU General Public License Version 3.
See L<https://www.gnu.org/licenses/gpl-3.0-standalone.html>.

=head1 BUGS AND LIMITATIONS

=cut
