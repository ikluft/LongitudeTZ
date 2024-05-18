#!/usr/bin/env perl
# cli-test-perl.t - run LongitudeTZ black box tests for Perl implementation
# by Ian Kluft (IKLUFT), ikluft@cpan.org
# created 05/04/2024 10:34:11 AM

use strict;
use warnings;
use Config;
use File::Basename;
use FindBin qw($Bin);

# collect parameters
my $debug     = ( $ENV{LONGITUDE_TZ_TEST_DEBUG} // 0 ) ? 1 : 0;
my $bin_dir   = $Bin;
my $tree_root = dirname($bin_dir);
my $perl_path = $Config{perlpath};

# run black box test command
exec $perl_path $perl_path, "$bin_dir/cli-test.pl", ( $debug ? "--debug" : () ), "$tree_root/src/perl/bin/lon-tz.pl";
