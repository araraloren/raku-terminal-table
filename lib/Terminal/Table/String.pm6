
use v6;
use Text::Tabs;
use Terminal::WCWidth;
use Terminal::Table::Settings;
use Terminal::Table::Exception;

sub noexpand-width(Str $str) returns Int is export {
    return wcswidth($str);
}

sub expand-width(Str $str, Int $tabstop) returns Int is export {
    return wcswidth(expand([$str], $tabstop)[0]);
}

class String is Str {
    has Int $.width;
    has     $.style;

    submethod TWEAK(:$value, :$width) {
        $!width = ?$width ?? $width !! expand-width($value, tabstop());
    }

    method extend-to(Int $width) {
        unless $width %% $!width {
            X::Kinoko::Error.new(msg => 'Extend width must be divides by string width').throw();
        }
        return self.new(value => self.Str() x ( $width div $!width ), width => $width );
    }

    method expand() {
        self.new(value => expand([self.Str()], tabstop())[0], :$!width);
    }

    method unexpand() {
        self.new(value => unexpand([self.Str()], tabstop())[0], :$!width);
    }

    method clone() {
        self.new(value => self.Str::clone(), :$!width);
    }

    multi method Str() {
        self.Str::Str();
    }

    multi method Str($shader) {
        if $!style {
            return $shader.colour(self.Str(), $!style);
        } else {
            return self.Str();
        }
    }

    method colored() {
        $!style && $!style.enabled;
    }

    method set-style($style) {
        $!style = $style;
        self;
    }

    method color() {
        unless $!style {
            return False;
        }
        return $!style.enabled || $!style.enable();
    }

    method uncolor() {
        if self.colored() {
            $!style.disable();
        }
        return True;
    }

    method perl() {
        return self.defined ?? "String.new(value => \"{self.Str()}\"," ~
            " width => {$!width}, style => {$!style.perl})" !! "(String)";
    }
}
