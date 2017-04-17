
use v6;
use Text::Table::Kinoko::KString;
use Text::Table::Kinoko::Generator;
use Text::Table::Kinoko::Style;
use Text::Table::Kinoko::Frame;

dd makeLine('xx', 2);

my $g = Generator.new(
    style => Style.new(
        corner-style => Style::Corner.double(),
        line-style => Style::Line.double(),
        content-style => Style::Content.space(),
    )
);

$g.add-cell(1);
$g.add-cell(2);
$g.add-cell(3);
$g.end-line;

$g.print;

my $g1 = Generator.new(
    style => Style.new(
        corner-style => Style::Corner.single(),
        line-style => Style::Line.single(),
        content-style => Style::Content.space(),
    )
);

$g1.add-cell(23);
$g1.add-cell(2);
$g1.add-cell(456);
$g1.end-line;
$g1.add-cell(2);
$g1.add-cell(2);
$g1.add-cell(2);
$g1.end-line;
$g1.add-cell(2);
$g1.add-cell(2);
$g1.add-cell('zuio');
$g1.end-line;

$g1.print;

$g.join($g1, :preserve-style);
my $table = $g.gen-table();

$table.print;
