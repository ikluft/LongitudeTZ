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
use Getopt::Long;
use Math::Trig ':pi';
use IPC::Run qw(run);
use GD;
use GD::Text::Align;

# constants
Readonly::Scalar my $font_path         => "/usr/share/fonts:/usr/share/fonts/gnu-free:/usr/share/fonts/liberation-mono-fonts";
Readonly::Scalar my $font_sans         => "FreeSans.ttf";
Readonly::Scalar my $font_sans_bold    => "FreeSansBold.ttf";
Readonly::Scalar my $font_mono         => "LiberationMono-Regular.ttf";
Readonly::Scalar my $font_mono_bold    => "LiberationMono-Bold.ttf";
Readonly::Scalar my $default_pt_size   => 14;
Readonly::Scalar my $lon_pt_size       => 16;
Readonly::Scalar my $title_pt_size     => 56;
Readonly::Scalar my $subtitle_pt_size  => 32;
Readonly::Scalar my $url_pt_size       => 18;
Readonly::Scalar my $author_pt_size    => 14;
Readonly::Scalar my $in_file           => "world_outline_map.svg";
Readonly::Scalar my $rsvg_convert_path => "/usr/bin/rsvg-convert";

Readonly::Scalar my $time_zones_wide   => 24;
Readonly::Scalar my $time_zones_narrow => 96;
Readonly::Scalar my $tz_pt_size_wide   => 24;
Readonly::Scalar my $tz_pt_size_narrow => 14;

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

# draw boxes on image for time zones
sub draw_boxes
{
    my $img = shift;
    my $narrow_flag = shift;

    my $img_width  = $img->width;
    my $img_height = $img->height;

    my $time_zones = $narrow_flag ? $time_zones_narrow : $time_zones_wide;
    my $alpha_light_gray = $img->colorAllocateAlpha( 191, 191, 191, 96 );
    for ( my $i = $time_zones - 1 ; $i >= 0 ; $i -= 2 ) {
        $img->filledRectangle(
            ( $i - 0.5 ) * ( $img_width / $time_zones ),
            $img_height * 0.056,
            ( $i + 0.5 ) * ( $img_width / $time_zones ) - 1,
            $img_height * 0.944 - 1,
            $alpha_light_gray
        );
    }
}

# generate time zone name string
sub tz_name_str
{
    my $narrow_flag = shift;
    my $num = shift;
    my $ew = shift;

    # compute optional offset suffix
    my $suffix = "";
    if ( $num == 0 ) {
        $suffix = "  0:00 UTC";
    } elsif ( $narrow_flag ) {
        my $zones_per_hr = $time_zones_narrow / $time_zones_wide;
        $suffix = sprintf " %s%d:%02d", $ew < 0 ? "-" : "+", $num / $zones_per_hr,
            ( $num % $zones_per_hr ) * 60 / $zones_per_hr;
    } else {
        $suffix = sprintf " %s%d:00", $ew < 0 ? "-" : "+", $num;
    }

    # format and return time zone name string
    if ( $narrow_flag ) {
        return sprintf "Narrow%02d%s%s", $num, $ew < 0 ? "W" : "E", $suffix;
    } else {
        return sprintf "%s%02d%s", $ew < 0 ? "West" : "East", $num, $suffix;
    }
}

# draw time zone names on image
sub draw_tz_names
{
    my $img = shift;
    my $narrow_flag = shift;

    my $color_lime_green = $img->colorAllocate( 50,  205, 50 );
    my $img_width  = $img->width;
    my $img_height = $img->height;
    my $time_zones = $narrow_flag ? $time_zones_narrow : $time_zones_wide;
    my $tz_pt_size = $narrow_flag ? $tz_pt_size_narrow : $tz_pt_size_wide;

    draw_text($img,
        tz_name_str($narrow_flag, $time_zones / 2, -1), 
        0.25 * ( $img_width / $time_zones ) + 1,
        $img_height - 80,
        { color => $color_lime_green, font => $font_mono_bold, pt_size => $tz_pt_size, angle => pip2,
            valign => "center", halign => "left" });
    for ( my $west_tz = $time_zones / 2 - 1; $west_tz > 0; $west_tz-- ) {
        draw_text($img,
            tz_name_str($narrow_flag, $west_tz, -1),
            ( $time_zones / 2 - $west_tz ) * ( $img_width / $time_zones ) + 1,
            $img_height - 80,
            { color => $color_lime_green, font => $font_mono_bold, pt_size => $tz_pt_size, angle => pip2,
                valign => "center", halign => "left" });

    }
    draw_text($img,
        tz_name_str($narrow_flag, 0, 1),
        $time_zones / 2 * ( $img_width / $time_zones ) - 1,
        $img_height - 80,
        { color => $color_lime_green, font => $font_mono_bold, pt_size => $tz_pt_size, angle => pip2,
            valign => "center", halign => "left" });
    for ( my $east_tz = 1; $east_tz < $time_zones / 2; $east_tz++ ) {
        draw_text($img,
            tz_name_str($narrow_flag, $east_tz, 1),
            ( $time_zones / 2 + $east_tz ) * ( $img_width / $time_zones ) + 1,
            $img_height - 80,
            { color => $color_lime_green, font => $font_mono_bold, pt_size => $tz_pt_size, angle => pip2,
                valign => "center", halign => "left" });

    }
    draw_text($img,
        tz_name_str($narrow_flag, $time_zones / 2, 1), 
        ( $time_zones - 0.25 ) * ( $img_width / $time_zones ) - 1,
        $img_height - 80,
        { color => $color_lime_green, font => $font_mono_bold, pt_size => $tz_pt_size, angle => pip2,
            valign => "center", halign => "left" });
}

#
# mainline
#

# process command-line arguments
my $narrow_flag = 0;
GetOptions( "narrow" => \$narrow_flag )
    or croak "usage: $0 [--narrow]";

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
my $img_width  = $img->width;
my $img_height = $img->height;
my $color_black      = $img->colorAllocate( 0,   0,   0 );
my $color_steel_blue = $img->colorAllocate( 70,  130, 180 );
my $color_dark_gray  = $img->colorAllocate( 63,  63,  63 );
$img->alphaBlending(1);

# draw boxes
draw_boxes( $img, $narrow_flag );

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

# draw longitude text: 0 is UTC
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
draw_tz_names($img, $narrow_flag);

# top titles
my @title_box = draw_text($img, "Natural Time Zones by Longitude" . ( $narrow_flag ? ": 15 minute zones" : "" ),
    $img_width / 2 - 1, 20,
    { color => $color_steel_blue, font => $font_sans_bold, pt_size => $title_pt_size, halign => "center" });
draw_text($img, "proposed addition to the TZ Database", $img_width / 2 - 1, $title_box[1] + 10,
    { color => $color_steel_blue, font => $font_sans_bold, pt_size => $subtitle_pt_size, halign => "center" });

# attribution
draw_text($img, "https://ikluft.github.io/LongitudeTZ/", 0.25 * ( $img_width / 24 ) + 1, $img_height * 0.4,
    { color => $color_black, font => $font_mono, pt_size => $url_pt_size, angle => pip2,
        valign => "center", halign => "center" });
draw_text($img, "by Ian Kluft, Longitude Time Zones Project", $img_width - 0.25 * ( $img_width / 24 ) + 1, $img_height * 0.4,
    { color => $color_black, font => $font_sans, pt_size => $author_pt_size, angle => pip2,
        valign => "center", halign => "center" });

# output the image
say $img->png();
