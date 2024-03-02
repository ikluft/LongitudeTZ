#!/usr/bin/env perl
# ABSTRACT: command-line interface for Perl implementation of LongitudeTZ library
# PODNAME: lon-tz.pl
# CREATED: 2024-02-27
# part of Perl implementation of solar timezones library
#
# Copyright © 2024 Ian Kluft. This program is free software; you can
# redistribute it and/or modify it under the terms of the GNU General Public
# License Version 3. See  https://www.gnu.org/licenses/gpl-3.0-standalone.html

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use Modern::Perl qw(2018);
## use critic (Modules::RequireExplicitPackage)

use strict;
use warnings;
use utf8;
use autodie;
use Carp qw(croak);
use Getopt::Long;
use Try::Tiny;
use TimeZone::Solar;
use Readonly;
use File::Basename;

# constants
Readonly::Scalar my $progname => basename( $0 );

# CLI-parsing mainline called from exception-catching wrapper
sub main
{
    my %opts;
    my $res = GetOptions (
        'version|v' => sub {
            say "version ".TimeZone::Solar->version();
            exit 0;
        },
    );
    if ( not $res ) {
        croak "CLI option processing failed";
    }
    # TODO
}

# exception-catching wrapper
try {
    &main();
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
}
1;
