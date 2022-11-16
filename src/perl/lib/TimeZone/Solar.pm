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
