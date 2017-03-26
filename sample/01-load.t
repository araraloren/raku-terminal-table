
use v6;
use Text::Table::Kinoko::Char;
use Text::Table::Kinoko::Table;
use Text::Table::Kinoko::Styler;

my $table = Table.new(
    styler => Styler.new(
        corner-styler => Styler::Corner.default(),
        line-styler => Styler::Line.default(),
    )
);

dd $table;

$table.add-cell(Char.new(str => "1"));
$table.add-cell(Char.new(str => "2"));
$table.end-line;
$table.add-cell(Char.new(str => "3"));
$table.add-cell(Char.new(str => "4"));
$table.add-cell(Char.new(str => "5"));
$table.end-line;
$table.add-cell(Char.new(str => "6"));
$table.add-cell(Char.new(str => "7"));
$table.add-cell(Char.new(str => "8"));
$table.add-cell(Char.new(str => "9"));
$table.add-cell(Char.new(str => "0"));
$table.end-line;


$table.print;
