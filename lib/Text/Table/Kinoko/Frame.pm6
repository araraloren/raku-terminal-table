
use v6;
use Text::Table::Kinoko::Char;

role Frame {
    has Char $.char;
    has Int  $.n;
    has Char $!cache;

    multi method new(Char :$char, :$n = 1) {
        self.bless(
            char => $char,
            :$n
        );
    }

    method Str() {
        return self.Char().Str();
    }

    method count() {
        return $!n;
    }

    method extend($width) {
        return self.bless(
            char => $!char,
            n => $width div $!char.width
        );
    }

    method width() {
        $!n * $!char.width;
    }

    method Char() { ... }
}

class Line does Frame {
    multi method new(Str :$str, :$width, :$n = 1) {
        self.bless(
            char => Char.new(:$str, :$width),
            :$n
        );
    }

    method Char() {
        return $!cache // do {
            $!cache = $!char.repeat($!n);
            $!cache;
        };
    }
}

class Corner does Frame {
    multi method new(Str :$str, :$width, :$n = 1) {
        self.bless(
            char => Char.new(:$str, :$width),
            :$n
        );
    }

    method Char() {
        return $!char;
    }
}

multi sub makeLine(Str $str) is export {
    return Line.new(:$str, n => 1);
}

multi sub makeLine(Str $str, $width) is export {
    return Line.new(:$str, :$width, n => 1);
}

sub makeLineArray(@sarray) is export {
    my @ret;
	@ret.push(makeLine($_)) for @sarray;
	return @ret;
}

sub makeLineArray2(@sarray) is export {
    my @ret;

    for @sarray -> $inner {
        my @t;
        @t.push(makeLine($_)) for @$inner;
        @ret.push(@t);
    }
    return @ret;
}

multi sub makeCorner(Str $str) is export {
    return Corner.new(:$str);
}

multi sub makeCorner(Str $str, $width) is export {
    return Corner.new(:$str, :$width);
}

sub makeCornerArray(@sarray) is export {
    my @ret;
	@ret.push(makeCorner($_)) for @sarray;
	return @ret;
}

sub makeCornerArray2(@sarray) is export {
    my @ret;

    for @sarray -> $inner {
        my @t;
        @t.push(makeCorner($_)) for @$inner;
        @ret.push(@t);
    }
    return @ret;
}
