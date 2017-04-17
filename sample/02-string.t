use v6;
use Text::Table::Kinoko::LightWrap;

my $str = "I want go to bed now! Tomorrow is already coming soon!";

say "|$_|" for split-w($str, 16);