
use v6;
use Text::Table::Kinoko::Brick;
use Text::Table::Kinoko::Wall;
use Text::Table::Kinoko::Corner;

unit class Cell;

has Str $.value;
has Int $.width;
has Str $!cache;
# has Bool    $!multi-line = False;

method new (:$value!, :$width!) {
    self.bless(:$value, :$width);
}

method align(Int $formated-width, Brick $padding, Styler::Align $align) {
    my $count = ($formated-width - $!width) div $padding.width;
    $!cache = do given $align {
        when Styler::Align::MIDDLE {
            ($padding.Str x $count) ~ $!value ~ ($padding.Str x $count);
        }
        when Styler::Align::LEFT {
            ($padding.Str x $count) ~ $!value;
        }
        when Styler::Align::RIGHT {
            $!value ~ ($!padding-char x $padding);
        }
    }
}

method Str() {
    $!cache; 
}



