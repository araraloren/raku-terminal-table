#!/usr/bin/env perl6

use Terminal::Table::Style;
use Terminal::Table::Generator;

my $gl = Generator.new(
    style => Style.new(
        corner-style => Style::Corner.double(),
        line-style   => Style::Line.double(),
        content-style=> Style::Content.space(),
    )
);

for 1 .. 9 -> \x {
    for 1 .. x -> \y {
        $gl.add-cell("{y} x {x} = {x * y}");
    }
    $gl.end-line();
}

my $gr = Generator.new(
    style => Style.new(
        corner-style => Style::Corner.single(),
        line-style   => Style::Line.dot(),
        content-style=> Style::Content.space(),
    )
);

my @data;

for reverse 1 .. 9 -> \x {
    @data.push([ "{.Int} x {x} = {x * .Int}" for 1 .. x ]);
}

$gr.from-array(@data);
$gl.join($gr, :replace-style);

my $g = $gl.generator();

$g.colour(8, $_, Color::String.new(color => <red bold> )) for ^9;
$g.colour(9, $_, Color::String.new(color => <green bold> )) for ^9;
$g.print(:color);
