
use v6;
use Terminal::Table::String;
use Terminal::Table::Generator;
use Terminal::Table::Style;
use Terminal::Table::Frame;
use Terminal::Table::Shader;
use Terminal::ANSIColor;

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
$g1.add-cell('日本', Color::String.new(color => <red>));
$g1.end-line;
$g1.add-cell(Shader.colour('English', Color::String.new(color => <red underline>)));
$g1.add-cell('
    Are you ok?
Where are you from ?');
$g1.add-cell('American、England、Australian .etc');
$g1.end-line;

$g.join($g1, :preserve-style(False));
my $table = $g.generator();
$table.colour(1, 1, Color::String.new(color => <green>), 0);
$table.print(:color);
