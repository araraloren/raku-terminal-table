
use v6;
use Text::Table::Kinoko::Char;

role Frame {
    has Char $.char;
    has Int  $.n;
    has Char $!cache;

    method new(:$str, :$width, :$n) {
        self.bless(
            char => Char.new(:$str, :$width),
            :$n
        );
    }

    method Str() {
        return self.Char().Str();
    }

    method count() {
        return $!n;
    }

    method Char() { ... }
}

class Line does Frame {
    method Char() {
        return $!cache // do {
            $!cache = $!char.repeat($!n);
            $!cache;
        };
    }
}

class Corner does Frame {
    method new(:$char) {
        self.bless(:$char, n => 1);
    }

    method Char() {
        return $!char;
    }
}

