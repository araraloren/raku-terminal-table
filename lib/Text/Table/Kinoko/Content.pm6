
use v6;
use Text::Table::Kinoko::KString;
use Text::Table::Kinoko::Exception;

class Content {
    has KString $.char;

    multi method new(KString :$str) {
        self.bless( char => $str );
    }

    multi method new(Str :$str, :$width) {
        self.bless(
            char => KString.new(:$str, :$width)
        );
    }

    method align($width, $style) {
        my $padding-width = $width - $!char.width + $style.indent;

        if $style.align-middle {
            unless $style.indent %% 2 {
                X::Kinoko::Error.new(msg => 'indent width must be even number').throw();
            }
            my $padding = $style.padding-char x ($padding-width div 2);
            return self.new( str => KString.new(
                str => $padding ~ $!char.Str() ~ $padding ~ ($padding-width %% 2 ?? "" !! $style.padding-char),
                width => $!char.width + $padding-width
            ));
        }
        if $style.align-left {
            return self.new( str => KString.new(
                str => $!char.Str() ~ ($style.padding-char x $padding-width),
                width => $!char.width + $padding-width
            ));
        }
        if $style.align-right {
            return self.new( str => KString.new(
                str => ($style.padding-char x $padding-width) ~ $!char.Str(),
                width => $!char.width + $padding-width
            ));
        }
        X::Kinoko::Error.new(msg => 'Can not recognize align type!').throw();
    }

    method width() {
        $!char.width;
    }

    method Str() {
        self.KString().Str();
    }

    method KString() {
        return $!char;
    }

    method clone() {
        self.new(str => $!char.clone());
    }
}
