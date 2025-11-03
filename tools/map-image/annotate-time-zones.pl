#!/usr/bin/env perl
# FILE:   annotate-time-zones.pl
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
use GD::Text::Align;

# constants
Readonly::Scalar my $font_path        => "/usr/share/fonts:/usr/share/fonts/gnu-free";
Readonly::Scalar my $font_sans        => "FreeSans.ttf";
Readonly::Scalar my $font_sans_bold   => "FreeSansBold.ttf";
Readonly::Scalar my $default_pt_size  => 14;
Readonly::Scalar my $lon_pt_size      => 16;
Readonly::Scalar my $tz_pt_size       => 32;
Readonly::Scalar my $title_pt_size    => 56;
Readonly::Scalar my $subtitle_pt_size => 32;
Readonly::Scalar my $attrib_pt_size   => 22;
Readonly::Scalar my $in_file          => "world_outline_map.svg";
Readonly::Scalar my $rsvg_convert_path => "/usr/bin/rsvg-convert";

#
# functions
#

# draw text at specified position, color, font, size, angle and alignment
sub draw_text
{
    my ( $img, $text, $x, $y, $attr ) = @_;

    # collect parameters
    if ( not defined $attr ) {
        $attr = {}
    }
    my $color = $attr->{color} // $img->colorClosest(63, 63, 63);
    my $font = $attr->{font} // $font_sans;
    my $pt_size = $attr->{pt_size} // $default_pt_size;
    my $angle = $attr->{angle} // 0;
    my $valign = $attr->{valign} // "top";
    my $halign = $attr->{halign} // "left";

    # construct GD::Text::Align object and draw it
    my $align = GD::Text::Align->new($img, valign => $valign, halign => $halign);
    $align->set_font($font, $pt_size);
    $align->set(color => $color);
    $align->set_text($text);
    return $align->draw($x, $y, $angle);
}

#
# mainline
#

# set up input pipeline from SVG file to PNG to GD
my ( $png_data, $err_out );
run( [ $rsvg_convert_path ], "<", $in_file, ">", \$png_data, "2>", \$err_out )
    or croak "$0: rsvg_convert command failed: $err_out";
if ($err_out) {
    croak "$0: errors in rsvg_convert command: $err_out";
}

# set up to generate image
GD::Image->trueColor(1);
GD::Text->font_path($font_path);
my $img = GD::Image->newFromPngData($png_data);
Readonly::Scalar my $img_width  => $img->width;
Readonly::Scalar my $img_height => $img->height;
my $color_black      = $img->colorAllocate( 0,   0,   0 );
my $color_steel_blue = $img->colorAllocate( 70,  130, 180 );
my $color_lime_green = $img->colorAllocate( 50,  205, 50 );
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
    draw_text( $img, "-" . $lon . "°", $base_left + 3, $img_height - 5,
        { color => $color_dark_gray, pt_size => $lon_pt_size, angle => pip2, valign => "top", halign => "left" });

    # east longitude are positive numbers 0 to +180
    my $base_right = ( 180 + $lon ) * ( $img_width / 360 );
    $img->line(
        $base_right - 1,
        $img_height - 1,
        $base_right - 1,
        $img_height - 30,
        $color_black
    );
    draw_text( $img, "+" . $lon . "°", $base_right - 3, $img_height - 5,
        { color => $color_dark_gray, pt_size => $lon_pt_size, angle => pip2, valign => "bottom", halign => "left" });
}

# 0 is UTC
my $centerline = 180 * ( $img_width / 360 );
$img->line(
    $centerline,
    $img_height - 1,
    $centerline,
    $img_height - 30,
    $color_black
);
draw_text( $img, "0°", 180 * ( $img_width / 360 ), $img_height - 35,
    { color => $color_dark_gray, pt_size => $lon_pt_size, angle => pip2, valign => "center", halign => "left" });

# draw time zone names
draw_text($img, "West12", 0.25 * ( $img_width / 24 ) + 1, $img_height - 80,
    { color => $color_lime_green, font => $font_sans_bold, pt_size => $tz_pt_size, angle => pip2,
        valign => "center", halign => "left" });
for ( my $west_tz = 11; $west_tz > 0; $west_tz-- ) {
    draw_text($img, sprintf( "West%02d", $west_tz), ( 12 - $west_tz ) * ( $img_width / 24 ) + 1, $img_height - 80,
        { color => $color_lime_green, font => $font_sans_bold, pt_size => $tz_pt_size, angle => pip2,
            valign => "center", halign => "left" });

}
draw_text($img, "East00 / UTC", 12 * ( $img_width / 24 ) - 1, $img_height - 80,
    { color => $color_lime_green, font => $font_sans_bold, pt_size => $tz_pt_size, angle => pip2,
        valign => "center", halign => "left" });
for ( my $east_tz = 1; $east_tz < 12; $east_tz++ ) {
    draw_text($img, sprintf( "East%02d", $east_tz), ( 12 + $east_tz ) * ( $img_width / 24 ) + 1, $img_height - 80,
        { color => $color_lime_green, font => $font_sans_bold, pt_size => $tz_pt_size, angle => pip2,
            valign => "center", halign => "left" });

}
draw_text($img, "East12", ( 24 - 0.25 ) * ( $img_width / 24 ) - 1, $img_height - 80,
    { color => $color_lime_green, font => $font_sans_bold, pt_size => $tz_pt_size, angle => pip2,
        valign => "center", halign => "left" });

# top titles
my @title_box = draw_text($img, "Natural Time Zones by Longitude", $img_width / 2 - 1, 20,
    { color => $color_steel_blue, font => $font_sans_bold, pt_size => $title_pt_size, halign => "center" });
draw_text($img, "proposed addition to the TZ Database", $img_width / 2 - 1, $title_box[1] + 10,
    { color => $color_steel_blue, font => $font_sans_bold, pt_size => $subtitle_pt_size, halign => "center" });

# attribution
draw_text($img, "https://github.com/ikluft/LongitudeTZ", 0.25 * ( $img_width / 24 ) + 1, $img_height / 2,
    { color => $color_black, font => $font_sans, pt_size => $attrib_pt_size, angle => pip2,
        valign => "center", halign => "center" });

# output the image
say $img->png();
