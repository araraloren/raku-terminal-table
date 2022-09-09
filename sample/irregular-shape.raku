#!/usr/bin/env raku

use v6;
use Terminal::Table;

my $g = create-generator([
    < A B C D E F >,
    < G H I J K L >,
    < M N O P Q R >,
    < S T U V W X >,
]);

$g.generate;

my &hide = -> $x, $y {
    my ($r, $c) = ($g.row-count() * 2, $g.col-count($x) * 2);
    my ($rx, $ry) = ($x * 2, $y * 2);

    my $top = $rx == 0 || $g.is-hidden($rx - 1, $ry + 1);
    my $top-left = ($rx == 0 || $ry == 0) || $g.is-hidden($rx - 1, $ry - 1);
    my $top-right = ($rx == 0 || $ry + 2 == $c) || $g.is-hidden($rx - 1, $ry + 3);
    my $bottom = ($rx + 2 == $r) || $g.is-hidden($rx + 3, $ry + 1);
    my $bottom-left = ($rx + 2 == $r || $ry == 0) || $g.is-hidden($rx + 3, $ry - 1);
    my $bottom-right = ($rx + 2 == $r || $ry + 2 == $c) || $g.is-hidden($rx + 3, $ry + 3);
    my $left = $ry == 0 || $g.is-hidden($rx + 1, $ry - 1);
    my $right = ($ry + 2 == $c) || $g.is-hidden($rx + 1, $ry + 3);

    if $top && $top-left && $left {
        $g.hide($rx, $ry, :replace-with-space);
    }
    if $top {
        $g.hide($rx, $ry + 1, :replace-with-space);
    }
    if $top && $top-right && $right {
        $g.hide($rx, $ry + 2, :replace-with-space);
    }
    if $left {
        $g.hide($rx + 1, $ry, :replace-with-space);
    }
    if $right {
        $g.hide($rx + 1, $ry + 2, :replace-with-space);
    }
    if $left && $bottom-left && $bottom {
        $g.hide($rx + 2, $ry, :replace-with-space);
    }
    if $bottom {
        $g.hide($rx + 2, $ry + 1, :replace-with-space);
    }
    if $right && $bottom-right && $bottom {
        $g.hide($rx + 2, $ry + 2, :replace-with-space);
    }
    $g.hide($rx + 1, $ry + 1, :replace-with-space);
};

for 1 .. 15 {
    my ($x, $y) = ((rand * 100).floor % 4, (rand * 100).floor % 6);

    &hide($x, $y);
}

$g.print;
