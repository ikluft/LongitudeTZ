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
        # safety check
        if ( $self->{latitude} > 90 or $self->{latitude} < -90 ) {
            croak "$class: latitude when provided must be in range -90..+90";
        }

        # special case: use Solar+00 (equal to UTC) within 10° latitude of poles
        if ( $self->{latitude} >= 80 or $self->{latitude} <= -80 ) {
            $self->name( "Solar+00" );
            $self->offset( 0 );
        }

        # otherwise fall through to set time zone from longitude as usual
    }

    #
    # set time zone from longitude
    #

    # set flag for longitude time zones: 0 = hourly 1-hour/15-degree zones, 1 = longitude 4-minute/1-degree zones
    # defaults to hourly time zone ($use_lon_tz=0)
    my $use_lon_tz = ( exists $self->{use_lon_tz} and $self->{use_lon_tz});
    if ( $use_lon_tz ) {
        # use longitude-based time zones: 1 degree longitude, 4 minutes time
        # TODO
    } else {
        # use hour-based time zones: 15 degrees longitude, 1 hour time
        # TODO
    }

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
