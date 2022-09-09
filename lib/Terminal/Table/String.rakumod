
use v6;
use Text::Tabs;
use Terminal::WCWidth;
use Terminal::Table::Settings;
use Terminal::Table::Exception;

sub noexpand-width(Str $str) returns Int is export {
    return wcswidth($str);
}

sub expand-width(Str $str, Int $tabstop) returns Int is export {
    return wcswidth(expand([$str], ts => $tabstop)[0]);
}

role ToWhiteSpace {
    method to-space() {
        return ' ' x self.width();
    } 
}

class String is Str does ToWhiteSpace {
    has Int $.width;
    has     $.style;

    submethod TWEAK(:$value, :$width) {
        $!width = ?$width ?? $width !! expand-width($value, tabstop());
    }

    method extend-to(Int $width) {
        my Str $value = ($!width == 0 && $width > 0) ?? &zero-padding() !! self.Str();
        if $!width > 0 {
            unless $width %% $!width {
                X::Kinoko::Error.new(msg => 'Extend width must be divides by string width')
                .throw();
            }
            return self.new(value => $value x ( $width div $!width ), width => $width );
        } else {
            return self.new(value => $value x $width, width => $width );
        }
    }

    method expand() {
        self.new(value => expand([self.Str(), ], tabstop())[0], :$!width);
    }

    method unexpand() {
        self.new(value => unexpand([self.Str(), ], tabstop())[0], :$!width);
    }

    method clone(*%_) {
        nextwith(
            width => %_<width> // $!width,
            style => %_<style> // $!style.clone(),
            |%_
        );
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

    method lines() {
         return [
             self.new(value => $_, :$!style)
                for split(/\n/, self.Str())
         ];
    }

    method coloured() {
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
        if self.coloured() {
            $!style.disable();
        }
        return True;
    }

    method raku() {
        return self.defined ?? "String.new(value => \"{self.Str()}\"," ~
            " width => {$!width}, style => {$!style.raku})" !! "(String)";
    }
}
