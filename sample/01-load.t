
use v6;
use Text::Table::Kinoko::DeepClone;
use Text::Table::Kinoko::Char;
use Text::Table::Kinoko::Generator;
use Text::Table::Kinoko::Style;
use Text::Table::Kinoko::Frame;

dd makeLine('xx', 2);

my $g = Generator.new(
    style => Style.new(
        corner-style => Style::Corner.single(:bold),
        line-style => Style::Line.single(:bold),
        content-style => Style::Content.space(),
    )
);

$g.add-cell(1);
$g.add-cell(1);
$g.end-line;
$g.add-cell(1);
$g.add-cell(1);
$g.add-cell(1);
$g.end-line;
$g.add-cell(1);
$g.add-cell('一只羊');
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
$g1.end-line;
$g1.add-cell(2);
$g1.add-cell(2);
$g1.add-cell(2);
$g1.end-line;
$g1.add-cell(2);
$g1.add-cell(2);
$g1.end-line;

$g1.print;

$g.join($g1, :preserve-style);
my $table = $g.gen-table();

$table.print;
