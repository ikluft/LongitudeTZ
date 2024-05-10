#!/usr/bin/env perl
# cli-test-python.t - run LongitudeTZ black box tests for Python implementation
# (this script is in Perl for 'prove' program to launch the tests consistently)
# by Ian Kluft (IKLUFT), ikluft@cpan.org
# created 05/09/2024

use strict;
use warnings;
use Config;
use File::Basename;
use FindBin qw($Bin);

# collect parameters
my $debug = ( $ENV{LONGITUDE_TZ_TEST_DEBUG} // 0 ) ? 1 : 0;
my $bin_dir = $Bin;
my $tree_root = dirname($bin_dir);
my $perl_path = $Config{perlpath};

# run black box test command
exec $perl_path $perl_path,
    "$bin_dir/cli-test.pl",
    ( $debug ? "--debug" : ()),
    "$tree_root/src/python/scripts/lon_tz.py";
