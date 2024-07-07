#!/usr/bin/env perl
# cli-test-cpp.t - run LongitudeTZ black box tests for C++ implementation
# (this script is in Perl for 'prove' program to launch the tests consistently)
# by Ian Kluft (IKLUFT), ikluft@cpan.org
# created 06/06/2024

use strict;
use warnings;
use feature qw(say);
use Config;
use Readonly;
use Carp qw(croak);
use Cwd;
use File::Basename;
use FindBin qw($Bin);
use File::Temp;
use File::Copy::Recursive qw(dircopy);
use IPC::Run;

# collect parameters
Readonly::Scalar my $debug => ( $ENV{LONGITUDE_TZ_TEST_DEBUG} // 0 ) ? 1 : 0;
Readonly::Scalar my $bin_dir => $Bin;
Readonly::Scalar my $tree_root => dirname($bin_dir);
Readonly::Scalar my $perl_path => $Config{perlpath};
Readonly::Scalar my $template => "tzsolar-cpp-buildXXXXXXXX";

# run a command directly without a shell
sub cmd
{
    my @cmd = @_;
    my $opts_ref = ( ref $cmd[0] eq "HASH" ) ? shift @cmd : {};
    my ($in, $out, $err);
    my $cmd = join " ", @cmd;
    if ( not IPC::Run::run \@cmd, \$in, \$out, \$err, IPC::Run::timeout( 120 )) {
        croak "'$cmd' exited with error code $?\nstdout: $out\nstderr: $err";
    }
    if (( $opts_ref->{out} // 0 ) ? 1 : 0 ) {
        say $out;
    }
    if ( $debug ) {
        say STDERR "'$cmd' succeeded";
        say STDERR "stdout: $out";
        say STDERR "stderr: $err";
        say STDERR "";
    }
    return;
}

# make temporary build directory
my %options = (CLEANUP => $debug ? 0 : 1);
my $tmpdir = File::Temp->newdir( $template, %options );

# keep for later with expected expansion of build directories
#for my $subdir (qw(bin lib src)) {
#    mkdir $tmpdir."/".$subdir, oct(775);
#}

# copy source to temporary directory and build it
## no critic (Variables::ProhibitPackageVars)
$File::Copy::Recursive::CopyLink = 0;
## critic (Variables::ProhibitPackageVars)
dircopy("$tree_root/src/cpp/libtzsolar", "$tmpdir");

# build in temporary directory
my $run_dir = getcwd;
chdir "$tmpdir";
cmd ({ out => 0 }, qw(make clean) );
cmd ({ out => 0 }, qw(make) );

# get out of build directory because it can't be cleaned up if we're in it
chdir "$run_dir";

# run black box test command
cmd ({ out => 1 }, $perl_path,
    "$bin_dir/cli-test.pl",
    ( $debug ? "--debug" : ()),
    "$run_dir/$tmpdir/libtzsolar/lon-tz");
