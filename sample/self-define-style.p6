#!/usr/bin/env perl6

use HTTP::Client;
use Terminal::Table::Style;
use Terminal::Table::Settings;
use Terminal::Table::Generator;

constant MODULE-LIST = 'http://modules.perl6.org';

my $client  = HTTP::Client.new;
my $respone = $client.get(MODULE-LIST);
my $c;

unless ($respone.success) {
    say "Can not get page: {MODULE-LIST}";
    exit -1;
}

$c = $respone.content;

my $g = Generator.new(
    style => Style.new(
        corner-style    => Style::Corner.new(
            style => [
                ['*', '*', '*'],
                ['*', '*', '*'],
                ['x', '*', 'x'],
            ],
            mode => OTHER
        ),
        line-style      => Style::Line.single(3),
        content-style   => Style::Content.new(
            align => MIDDLE
        )
    )
);

my regex github {
    '<a href="'$<link> = (<-[\"]>+)'"'<-[\>]>+'></a>'
    \s+
    '<a href="'<-[\"]>+'"'\s+'>' $<name> = (<-[\<\s]>+)\s*'</a>'
}

for @($c ~~ m:g/<github>/) {
    $g.add-cell(++$);
    $g.add-cell(.<github>.<name>);
    $g.add-cell(.<github>.<link>);
    $g.end-line;
}

my $tg = $g.generator();

my $linkstyle = Color::String.new(color => <green underline>);
my $namestyle = Color::String.new(color => <blue bold>);

for ^$tg.row-count {
    $tg.colour($_, 1, $namestyle);
    $tg.colour($_, 2, $linkstyle);
}
$tg.print(:color);
