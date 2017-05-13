#!/usr/bin/env perl6

use v6;
use Terminal::Table::Generator;
use Terminal::Table::Style;

my $g = Generator.new(
    style => Style.new(
        corner-style => Style::Corner.double(),
        line-style => Style::Line.double(),
        content-style => Style::Content.space(),
    )
);

$g.add-cell('Language');
$g.add-cell('Example');
$g.add-cell('Country');
$g.end-line;
$g.add-cell('Chinese');
$g.add-cell("你吃饭了吗？\n你好！\n你从哪里来？");
$g.add-cell('China');
$g.end-line;
$g.add-cell('Janpanese');
$g.add-cell('
ありがとうございます。
いただきます！');
$g.add-cell('Janpa');
$g.end-line;
$g.add-cell('English');
$g.add-cell('Nice to meet you!
Are you ok?
Where are you from ?');
$g.add-cell('American、England、Australian .etc');
$g.end-line;
$g.add-cell('Korean');
$g.add-cell('안녕하세요！');
$g.add-cell('Korea');
$g.end-line;
$g.generator.generate.print(:coloured);
