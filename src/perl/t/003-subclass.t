#!/usr/bin/env perl
# t/003-subclass.t - test TimeZone::Solar subclasses in DateTime::TimeZone::Solar::*
#
# Copyright © 2022 Ian Kluft. This program is free software; you can
# redistribute it and/or modify it under the terms of the GNU General Public
# License Version 3. See  https://www.gnu.org/licenses/gpl-3.0-standalone.html

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use strict;
use warnings;
## use critic (Modules::RequireExplicitPackage)

use utf8;
use Carp;
use Test::More;
use Test::Exception;
use Readonly;
use TimeZone::Solar;

# constants
Readonly::Scalar my $TZSOLAR_CLASS        => "TimeZone::Solar";
Readonly::Scalar my $TZSOLAR_CLASS_PREFIX => "DateTime::TimeZone::Solar::";
Readonly::Scalar my $MAX_HOURS            => 24;                              # maximum degrees = 24
Readonly::Scalar my $NARROW_PER_HOUR      => 4;                               # narrow time zones per hourly zone
Readonly::Scalar my $tests_per_class      => 5;
Readonly::Scalar my $total_tests => ( $MAX_HOURS * $NARROW_PER_HOUR + 2 ) * $tests_per_class +
    ( $MAX_HOURS + 2 ) * $tests_per_class;
Readonly::Hash my %differences => (

    # special cases where we expect different results than the class name given
    $TZSOLAR_CLASS_PREFIX . "West0000" => $TZSOLAR_CLASS_PREFIX . "East0000",
    $TZSOLAR_CLASS_PREFIX . "West1200" => $TZSOLAR_CLASS_PREFIX . "East1200",
    $TZSOLAR_CLASS_PREFIX . "West00"   => $TZSOLAR_CLASS_PREFIX . "East00",
    $TZSOLAR_CLASS_PREFIX . "West12"   => $TZSOLAR_CLASS_PREFIX . "East12",
);

# test a sigle subclass by name
sub test_subclass_name
{
    my $subclass = shift;
    isa_ok( $subclass, $TZSOLAR_CLASS );
    my $expect_type = exists $differences{$subclass} ? $differences{$subclass} : $subclass;
    my ( $obj, $obj2 );
    lives_ok( sub { $obj = $subclass->new() }, "instantiate $subclass from new()" );
    is( ref $obj, $expect_type, exists $differences{$subclass}
        ? "got $expect_type from $subclass as expected"
        : "got $subclass as expected" );
    lives_ok( sub { $obj2 = $subclass->instance() }, "get instance() of $subclass" );
    ok( $obj eq $obj2, "eq comparison of $subclass objects" );
    return;
}

# tests for hour-based timezone subclasses
sub test_subclasses_hour
{
    for ( my $hour = -$MAX_HOURS / 2 ; $hour <= 0 ; $hour++ ) {
        test_subclass_name( sprintf "%sWest%02d", $TZSOLAR_CLASS_PREFIX, abs($hour) );
    }
    for ( my $hour = 0 ; $hour <= $MAX_HOURS / 2 ; $hour++ ) {
        test_subclass_name( sprintf "%sEast%02d", $TZSOLAR_CLASS_PREFIX, $hour );
    }
    return;
}

# tests for longitude-based timezone subclasses
sub test_subclasses_narrow
{
    test_subclass_name( $TZSOLAR_CLASS_PREFIX . "West1200" );
    for ( my $hour = -( $MAX_HOURS / 2 - 1 ) ; $hour <= 0 ; $hour++ ) {
        for ( my $min = 0 ; $min < 60 ; $min += 60 / $NARROW_PER_HOUR ) {
            test_subclass_name( sprintf "%sWest%02d%02d", $TZSOLAR_CLASS_PREFIX, abs($hour), $min );
        }
    }
    for ( my $hour = 0 ; $hour <= $MAX_HOURS / 2 - 1 ; $hour++ ) {
        for ( my $min = 0 ; $min < 60 ; $min += 60 / $NARROW_PER_HOUR ) {
            test_subclass_name( sprintf "%sEast%02d%02d", $TZSOLAR_CLASS_PREFIX, $hour, $min );
        }
    }
    test_subclass_name( $TZSOLAR_CLASS_PREFIX . "East1200" );
    return;
}

# main
plan tests => $total_tests;
test_subclasses_hour();
test_subclasses_narrow();
