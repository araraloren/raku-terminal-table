
use Test;
use Terminal::Table::Style;
use Terminal::Table::String;
use Terminal::Table::Settings;

plan 6;
my $str =  "It's a string.\t\nAnother Line.";

my $string = String.new(value => $str, style => Color::String.new(color => <red on_black>));

isa-ok($string, Str, "String is inherit from Str.");

is($str, $string);

is($string.width, expand-width($str, tabstop()));

ok($string.colored(), "String can have color style.");

$string.uncolor();
nok($string.colored(), "Disable color style.");

$string.color();
ok($string.colored(), "Enable color style.");
