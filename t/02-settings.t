

use Test;
use Terminal::Table::String;
use Terminal::Table::Settings;

plan 2;

my $str = "\t\t";

is(16, expand-width($str, tabstop()), "Default tab width is 8.");

$TABSTOP = 4;

is(8, expand-width($str, tabstop()),  "Set tab width to 4.");
