
use v6;
use Text::Table::Kinoko::String;
use Text::Table::Kinoko::Settings;
use Text::Table::Kinoko::LightWrap;
use Text::Table::Kinoko::Exception;

class Line {
    # use -n represent vertical line
    has String $.base;
    has Int    $.n;
    has        @!caches = [];

    method new(Str :$str, :$width, :$n = 1) {
        self.bless(base => String.new(:$str, :$width), :$n);
    }

    method width() {
        $!n > 0 ?? $!n * $!base.width !! $!base.width;
    }

    method height() {
        +@!caches;
    }

    method Str() {
        self.lines()[0];
    }

    # return Str array
    method lines() {
        return @!caches.elems > 0 ?? @!caches !! do {
            if $!n > 0 {
                @!caches[0] = $!base x $!n;
            } else {
                @!caches.push($!base.Str()) for ^abs($!n);
            }
            @!caches;
        };
    }

    method extend-to(Int $width, :$v) {
        unless $width %% $!base.width {
            X::Kinoko::Error.new(msg => 'width must be integer multiple of base width.').throw();
        }
        self.bless(base => $!base.clone(), n => ($width div $!base.width) * ($v ?? -1 !! 1));
    }

    method clone() {
        self.bless(base => $!base.clone(), :$!n);
    }

    method perl() {
        return self.defined ?? "Line.new(str => \"{$!base.Str}\", width => {$!base.width}, n => $!n)" !! "(Line)";
    }
}

class Corner {
    has String $.base;

    method new(Str :$str, :$width) {
        self.bless( base => String.new(:$str, :$width));
    }

    method width() {
        $!base.width;
    }

    method height() {
        1;
    }

    method Str() {
        self.String().Str();
    }

    method String() {
        return $!base;
    }

    method clone() {
        self.bless(:base($!base.clone()));
    }

    method perl() {
        return self.defined ?? "Corner.new(str => \"{$!base.Str}\", width => {$!base.width})" !! "(Corner)";
    }
}

class Content does Iterable {
    has @.lines handles < AT-POS >;

    multi method new(Str :$str) {
        self.bless()!__make_lines([$str]);
    }

    multi method new(@lines) {
        self.bless()!__make_lines(@lines);
    }

    sub make-lines(@lines) {
        my @r = [];
        for @lines -> $line {
            @r.push(String.new(str => $_)) for split /\n/, $line;
        }
        @r;
    }

    method !__make_lines(@lines) {
        @!lines = make-lines(@lines);
        self;
    }

    method align($width, $style) {
        #- table column max width = <- alinged string ->
        my $real-width = $width;
        my @lines = wrap(@!lines, :tabstop(tabstop()), :max-width($real-width), :force($style.split-word));
        my @temp = Array.new;
        for @lines -> $line {
            my $padding-width = $real-width - $line.width;
            unless $padding-width %% $style.padding-char.width {
                X::Kinoko::Error.new(msg => 'padding width must be divides by padding-char width').throw();
            }
            my $padding-count = $padding-width div $style.padding-char.width;
            @temp.push(
                do {
                    my Str $str = "";
                    if $style.align-middle {
                        my $padding = $style.padding-char x ($padding-count div 2);
                        $str ~= $padding;
                        $str ~= $line;
                        $str ~= $padding;
                        $str ~= ($padding-count %% 2 ?? "" !! $style.padding-char);
                    } elsif $style.align-left {
                        my $padding = $style.padding-char x $padding-count;
                        $str ~= $line;
                        $str ~= $padding;
                    } elsif $style.align-right {
                        my $padding = $style.padding-char x $padding-count;
                        $str ~= $padding;
                        $str ~= $line;
                    } else {
                        X::Kinoko::Error.new(msg => 'Can not recognize align type!').throw();
                    }
                    $str;
                }
            )
        }
        self.new(@temp);
    }

    method padding($style) {
        my @temp = Array.new;
        for @!lines -> $line {
            @temp.push(
                do {
                    my Str $str = "";
                    $str ~= $style.padding-char x $style.padding-left;
                    $str ~= $line;
                    $str ~= $style.padding-char x $style.padding-right;
                    $str
                }
            );
        }
        self.new(@temp);
    }

    method extend-v(Int $h) {
        my @temp = @!lines>>.Str();
        for self.height() ...^ $h {
            @temp.push(' ' x self.max-widths())
        }
        self.new(@temp);
    }

    method clone() {
        self.new(@!lines.clone());
    }

    method height() {
        +@!lines;
    }

    method max-width() {
        max(@!lines>>.width);
    }

    method items() {
        @!lines.elems;
    }

    method Int() {
        @!lines.elems;
    }

    method iterator() {
        @!lines.iterator();
    }
}
