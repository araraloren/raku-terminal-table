
use v6;
use Text::Table::Kinoko::String;
use Text::Table::Kinoko::Generator;
use Text::Table::Kinoko::Style;
use Text::Table::Kinoko::Frame;

my $g = Generator.new(
    style => Style.new(
        corner-style => Style::Corner.single(),
        line-style => Style::Line.single(),
        content-style => Style::Content.space(),
    )
);

$g.add-cell('语言');
$g.add-cell('sample');
$g.add-cell('markup');
$g.end-line;

$g.print;

my $g1 = Generator.new(
    style => Style.new(
        corner-style => Style::Corner.single(),
        line-style => Style::Line.single(),
        content-style => Style::Content.space(),
    )
);

$g1.add-cell('中文');
$g1.add-cell("你吃饭了吗？\n你是哪里人？");
$g1.add-cell('中国、新加坡');
$g1.end-line;
$g1.add-cell('にちぶん');
$g1.add-cell('こんにちは');
$g1.add-cell('日本');
$g1.end-line;
$g1.add-cell('English');
$g1.add-cell('Are you ok?
Where are you from ?');
$g1.add-cell('American、England、Australian .etc');
$g1.end-line;

$g1.print;

$g.join($g1, :preserve-style(False));
my $table = $g.gen-table();

$table.print;
