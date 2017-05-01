
use v6;
use Text::Tabs;
use Terminal::WCWidth;
use Text::Table::Kinoko::Settings;
use Text::Table::Kinoko::Exception;

sub noexpand-width(Str $str) returns Int is export {
    return wcswidth($str);
}

sub expand-width(Str $str, Int $tabstop) returns Int is export {
    return wcswidth(expand([$str], $tabstop)[0]);
}

class String is Str {
    has Int $.width;

    method new(Str :$str, :$width) {
        callwith(value => $str)!__set_width(?$width ?? $width !! expand-width($str, tabstop()));
    }

    method !__set_width($w) {
        $!width = $w;
        self;
    }

    method extend-to(Int $width) {
        unless $width %% $!width {
            X::Kinoko::Error.new(msg => 'Extend width must be divides by string width').throw();
        }
        return $?CLASS.new(value => self.Str() x ( $width div $!width ), width => $width );
    }

    method expand() {
        self.new(str => expand([self.Str()], tabstop())[0], :$!width);
    }

    method unexpand() {
        self.new(str => unexpand([self.Str()], tabstop())[0], :$!width);
    }

    method clone() {
        self.new(str => self.Str::clone(), :$!width);
    }

    method Str() {
        self.Str::Str();
    }

    method perl() {
        return self.defined ?? "String.new(str => \"{self.Str()}\", width => {$!width})" !! "(String)";
    }
}
