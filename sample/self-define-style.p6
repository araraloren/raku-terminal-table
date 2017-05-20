#!/usr/bin/env perl6

use HTTP::Client;
use Terminal::Table::Style;
use Terminal::Table::Settings;
use Terminal::Table::Generator;
use Terminal::Table::VisitorHelper;

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

my $linkstyle = Color::String.new(color => <green underline>);
my $namestyle = Color::String.new(color => <blue bold>);

for @($c ~~ m:g/<github>/) {
    $g.add-cell(++$);
    $g.add-cell(.<github>.<name>, $linkstyle);
    $g.add-cell(.<github>.<link>, $namestyle);
    $g.end-line;
}

my $tg = $g.generator();

$tg.set-callback(sub (|c) {
    my @lazy-array = &visitor-helper().generate(|c); # call same name help func

    for @lazy-array -> $line {
        .print for @($line);
        "".say;
    }
});

$tg.generate(:coloured);
