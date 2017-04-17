
use v6;
use Terminal::WCWidth;

class KString {
    has Str $.str;
    has Int $.width;

    method new(:$str is copy, :$width) {
        self.bless(:$str, width => ?$width ?? $width !! wcswidth($str));
    }

    method Str() {
        return $!str;
    }

    method codes() {
        return $!str.codes;
    }

    method width() {
        return $!width;
    }

    method repeat($n) {
        return KString.new(str => $!str x $n, width => $!width * $n);
    }

    method extend(Int $width) {
        return KString.new(str => $!str x ( $width div $!width ), width => $width );
    }

    method concat(KString $char) {
        return KString.new(str => $!str ~ $char.str, width => $!width + $char.width);
    }

    method clone() {
        self.new(:$!str, :$!width);
    }
}

multi sub makeKString(Str $str) is export {
	return KString.new(
		str => $str
	);
}

multi sub makeKString(Str $str, Int $width) is export {
	return KString.new(
		str => $str,
		width => $width
	);
}

sub makeKStringArray(@style) is export {
	my @ret;
	@ret.push(KString.new( str => $_ )) for @style;
	return @ret;
}

sub makeKStringArray2(@style) is export {
	my @ret;

	for @style -> $inner {
		my @t;
		@t.push(KString.new(
					   str => $_
				   )) for @$inner;
		@ret.push(@t);
	}
	return @ret;
}
