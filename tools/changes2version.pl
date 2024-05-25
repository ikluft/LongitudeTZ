#!/usr/bin/env perl
# changes2version.pl - use Changes file to manage semantic versioning and output a text template
# Copyright 2024 by Ian Kluft
# Released under GNU General Public License v3 https://www.gnu.org/licenses/gpl-3.0.html

use strict;
use warnings;
use utf8;
use feature qw(say);
use Carp    qw(carp croak);
use Readonly;
use Getopt::Long;
use File::Basename qw(basename);
use CPAN::Changes;
use Versioning::Scheme::Semantic;
use Template;

# constants
Readonly::Scalar my $Debug         => ( $ENV{LON_TZ_DEBUG} // 0 ? 1 : 0 );
Readonly::Scalar my $ChangesFile   => "Changes";
Readonly::Scalar my $VersionHeader => "version.hpp";
Readonly::Scalar my $NextTokenRE   => qr/\{\{\$NEXT\}\}/x;
Readonly::Scalar my $NextTokenStr  => '{{$NEXT}}';
Readonly::Scalar my $TT2Suffix     => ".tt2";
Readonly::Hash my %GroupOrder => (
    MAJOR        => 0, "API CHANGE" => 1, MINOR        => 2, ENHANCEMENTS => 3,
    SECURITY     => 4, REVISION     => 5, "BUG FIXES"  => 6, DOCS         => 7,
);
Readonly::Hash my %GroupLevel => (
    MAJOR        => 0, "API CHANGE" => 0, MINOR        => 1, ENHANCEMENTS => 1,
    SECURITY     => 1, REVISION     => 2, "BUG FIXES"  => 2, DOCS         => 2,
);

# debugging statements when enabled
sub debug
{
    my @text = @_;
    if ($Debug) {
        say STDERR "debug: " . join( " ", @text );
    }
    return;
}

# load changelog data
sub get_changes
{
    return CPAN::Changes->load( $ChangesFile, next_token => $NextTokenRE, );
}

# find which level of semantic versioning to increment
sub get_semver_level
{
    my $changes      = shift;
    my $semver_level = 2;
    my @releases     = $changes->releases();
    my @groups       = $releases[-1]->groups();
    foreach my $group (@groups) {
        debug "semver_level check($semver_level): $group/$GroupLevel{$group}";
        next if not exists $GroupLevel{$group};
        if ( $GroupLevel{$group} < $semver_level ) {
            $semver_level = $GroupLevel{$group};
            last if $semver_level == 0;
        }
    }
    debug "semver_level = $semver_level";
    return $semver_level;
}

# utility function: today's date
sub today_now
{
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = gmtime(time);
    $year += 1900;
    $mon++;
    return sprintf( "%04d-%02d-%02dT%02d:%02d:%02d UTC", $year, $mon, $mday, $hour, $min, $sec );
}

# generate a new blank {{NEXT}} block for the updated changelog
sub new_next_block
{
    my $block = CPAN::Changes::Release->new( version => $NextTokenStr, );
    $block->add_group( sort keys %GroupOrder );
    return $block;
}

# rewrite changelog file
sub rewrite_changes
{
    my $changes = shift;
    open( my $out_fh, ">", $ChangesFile )
        or croak "failed to open $ChangesFile for writing: $!";
    say $out_fh $changes->serialize()
        or croak "failed to write to $ChangesFile due to error: $!";
    close $out_fh
        or croak "failed to close $ChangesFile due to error: $!";
    return;
}

# write text file from template
sub write_template
{
    my %data      = @_;
    my $dest_file = $data{dest_file};
    my $tt2_file  = $data{tt2_file};

    # generate text from template
    my $template = Template->new( INTERPOLATE => 1, EVAL_PERL => 0 );
    $template->process( $tt2_file, \%data, $dest_file );
    return;
}

# collect command-line arguments to begin on template data
my %args;
GetOptions( \%args );

# remaining positional parameters are treated as template file names
my @tt2_files;
while ( my $arg = shift @ARGV ) {
    if ( substr( $arg, -4, 4 ) ne $TT2Suffix ) {
        croak "template file $arg does not have a $TT2Suffix suffix";
    }
    if ( not -f $arg ) {
        croak "template file $arg does not exist";
    }
    push @tt2_files, $arg;
}

# load changelog data
my $changes = get_changes();
debug "received changes:", $changes->serialize(), "";

# compute next version
$changes->delete_empty_groups();
my $semver_level = get_semver_level($changes);
my @releases     = $changes->releases();
my $rel_len      = scalar(@releases);
if ( $releases[ $rel_len - 1 ]->version() ne $NextTokenStr ) {
    croak "Changes file entries must be added under $NextTokenStr to compute next version";
}
my $prev_version = ( $rel_len >= 2 ) ? $releases[ $rel_len - 2 ]->version() : "0.0.0";
debug "prev_version = $prev_version";
my $prev_semver = Versioning::Scheme::Semantic->normalize_version($prev_version);    # exception if invalid
debug "prev_semver = $prev_semver";
my $next_semver = Versioning::Scheme::Semantic->bump_version( $prev_semver, { part => $semver_level } );
debug "next_semver = $next_semver";

# build new changelog content
my $next_release = $changes->release($NextTokenStr);
$changes->delete_release($NextTokenStr);
$next_release->version($next_semver);
$next_release->date( today_now() );
$changes->add_release( $next_release, new_next_block() );

# rewrite Changes file
rewrite_changes($changes);

# write template file(s)
my $semverdata = Versioning::Scheme::Semantic->parse_version($next_semver);
foreach my $tt2_file (@tt2_files) {
    my $dest_file = basename( $tt2_file, $TT2Suffix );
    write_template(
        dest_file => $dest_file,
        tt2_file  => $tt2_file,
        version   => $next_semver,
        semver    => $semverdata,
        args      => \%args,
        timestamp => today_now(),
    );
}
