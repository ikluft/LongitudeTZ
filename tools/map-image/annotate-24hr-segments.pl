#!/usr/bin/env perl
#   FILE: annotate-24hr-segments.pl
# AUTHOR: Ian Kluft (IKLUFT), ikluft@cpan.org
#===============================================================================

use strict;
use warnings;
use utf8;
use feature qw(say);
use Carp    qw(croak);
use Readonly;
use Math::Trig ':pi';
use IPC::Run qw(run);
use GD;
use GD::Text;

# constants
Readonly::Scalar my $font_sans     => "/usr/share/fonts/gnu-free/FreeSans.ttf";
Readonly::Scalar my $lon_pt_size   => 12;
Readonly::Scalar my $in_file       => "world_outline_map.svg";
Readonly::Scalar my $rsvg_convert_path => "/usr/bin/rsvg-convert";

# set up input pipeline from SVG file to PNG to GD
my ( $png_data, $err_out );
run( [ $rsvg_convert_path ], "<", $in_file, ">", \$png_data, "2>", \$err_out )
    or croak "$0: rsvg_convert command failed: $err_out";
if ($err_out) {
    croak "$0: errors in rsvg_convert command: $err_out";
}

# set up to generate image
GD::Image->trueColor(1);
my $img = GD::Image->newFromPngData($png_data);
Readonly::Scalar my $img_width  => $img->width;
Readonly::Scalar my $img_height => $img->height;
my $color_black      = $img->colorAllocate( 0,   0,   0 );
my $color_dark_gray  = $img->colorAllocate( 63,  63,  63 );
my $alpha_light_gray = $img->colorAllocateAlpha( 191, 191, 191, 96 );
$img->alphaBlending(1);

# draw boxes
for ( my $i = 23 ; $i >= 0 ; $i -= 2 ) {
    $img->filledRectangle(
        ( $i - 0.5 ) * ( $img_width / 24 ),
        0,
        ( $i + 0.5 ) * ( $img_width / 24 ) - 1,
        $img_height - 1,
        $alpha_light_gray
    );
}

# draw longitude text and marker lines
for ( my $lon = 180 ; $lon > 0 ; $lon -= 15 ) {

    # west longitude are negative numbers -180 to 0
    my $base_left = ( 180 - $lon ) * ( $img_width / 360 );
    $img->line(
        $base_left, $img_height - 1, $base_left, $img_height - 30,
        $color_black
    );
    $img->stringFT(
        $color_dark_gray, $font_sans, $lon_pt_size, pip2,
        $base_left + 2,
        $img_height - 15,
        "-" . $lon
    );

    # east longitude are positive numbers 0 to +180
    my $base_right = ( 180 + $lon ) * ( $img_width / 360 );
    $img->line(
        $base_right - 1,
        $img_height - 1,
        $base_right - 1,
        $img_height - 30,
        $color_black
    );
    $img->stringFT(
        $color_dark_gray, $font_sans, $lon_pt_size, pip2,
        $base_right - 3 - $lon_pt_size,
        $img_height - 15,
        "+" . $lon
    );
}

# 0 is UTC
$img->stringFT(
    $color_dark_gray, $font_sans, $lon_pt_size, pip2,
    180 * ( $img_width / 360 ) - $lon_pt_size / 2,
    $img_height - 15,
    "0 UTC"
);

# output the image
#say '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';
say $img->png();
