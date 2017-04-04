
use v6;
use Terminal::WCWidth;

class Char {
    has Str $.str;
    has Int $.width;

    method new(:$str is copy, :$width) {
        self.bless(:$str, width => ?$width ?? $width !! wcswidth($str));
    }

    method Str() {
        return $!str;
    }

    method width() {
        return $!width;
    }

    method repeat($n) {
        return Char.new(str => $!str x $n, width => $!width x $n);
    }

    method extend(Int $width) {
        return Char.new(str => $!str x ( $width div $!width ), width => $width );
    }

    method concat(Char $char) {
        return Char.new(str => $!str ~ $char.str, width => $!width + $char.width);
    }

    method clone() {
        self.new(:$!str, :$!width);
    }
}
