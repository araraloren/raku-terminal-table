
use v6;
use Text::Table::Kinoko::Char;
use Text::Table::Kinoko::Exception;

class Content {
    has Char $.char;

    multi method new(:$str, :$width) {
        self.bless(
            char => Char.new(:$str, :$width)
        );
    }

    multi method align(Int $n, :$middle) {
        unless $n %% 2 {
            X::Kinoko::Error.new(msg => 'indent width must be even number').throw();
        }
        my $space = ' ' x ($n div 2);
        return Content.new(
            char => Char.new(
                str => $space ~ $!char.Str() ~ $space,
                width => $!char.width + $n
            );
        )
    }

    multi method align(Int $n, :$left) {
        return Content.new(
            char => Char.new(
                str => $!char.Str() ~ (' ' x $n),
                width => $!char.width + $n
            );
        )
    }

    multi method align(Int $n, :$right) {
        return Content.new(
            char => Char.new(
                str => (' ' x $n) ~ $!char.Str(),
                width => $!char.width + $n
            );
        )
    }

    method Str() {
        self.Char().Str();
    }

    method Char() {
        return $!char;
    }
}