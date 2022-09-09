
use Test;
use Terminal::Table::String;
use Terminal::Table::Settings;
use Terminal::Table::LightWrap;

plan 4;

my $str = String.new(value => "");

my @empty-string-wrap-r = wrap($str, max-width => 5, tabstop => tabstop());

ok(@empty-string-wrap-r[0] eq String.new(value => ""), "Wrap empty string");

my @str = [ String.new(value => ""), String.new(value => "you are\ns") ];

my @r = wrap(@str, max-width => 7, tabstop => tabstop());
my @er = [
	String.new(value => ""),
	String.new(value => "you are"),
	String.new(value => "s")
];

for @r Z, @er -> ($a, $b) {
	ok($a eq $b, "wrap ok");
}
