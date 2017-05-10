
use v6;
use Terminal::Table::String;
use Terminal::Table::Settings;
use Terminal::Table::LightWrap;
use Terminal::Table::Exception;

class Line {
    # use -n represent vertical line
    has String $.base;
    has Int    $.n      = 1;
    has        @!caches = [];

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

    method get-line($i) {
        return self.lines()[$i];
    }

    method extend-to(Int $width, :$v) {
        unless $width %% $!base.width {
            X::Kinoko::Error.new(msg => 'width must be integer multiple of base width.').throw();
        }
        self.new(base => $!base.clone(), n => ($width div $!base.width) * ($v ?? -1 !! 1));
    }

    method clone() {
        self.new(base => $!base.clone(), :$!n);
    }

    method perl() {
        return self.defined ?? "Line.new(base => \"{$!base.perl}\", n => $!n)" !! "(Line)";
    }
}

class Corner {
    has String $.base;

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
        self.new(:base($!base.clone()));
    }

    method perl() {
        return self.defined ?? "Corner.new(base => \"{$!base.perl}\")" !! "(Corner)";
    }
}

class Content { ... };

sub make-lines(@lines) {
    my @r = [];
    for @lines -> $line {
        @r.push(String.new(value => $_)) for split /\n/, $line;
    }
    @r;
}

class Content {
    my class Content::Padding {
        has $.pl is rw = "";
        has $.wl is rw = 0;
        has $.pr is rw = "";
        has $.wr is rw = 0;

        method clone() {
            return self.new(:$!wl, :$!wr, pl => $!pl.clone(), pr => $!pr.clone());
        }

        method width() {
            $!wl + $!wr;
        }
    }

    has @.padding;
    has @.lines handles < AT-POS ASSIGN-POS >;

    method new-from-str(Str $str) {
        self.bless()!__make_lines([$str]);
    }

    method new(String $str) {
        self.bless(lines =>
            [
            String.new(value => $_, style => $str.style)
                for split /\n/, $str.Str()
            ]
        );
    }

    method new-from-str-array(@lines) {
        self.bless()!__make_lines(@lines);
    }

    method new-from-string-array(@lines) {
        self.bless(lines => @lines);
    }

    method new-from-string-array-padding(@lines, @padding) {
        self.bless(lines => @lines, padding => @padding);
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
                    my Content::Padding $cp .= new;
                    if $style.align-middle {
                        my $padding = $style.padding-char x ($padding-count div 2);
                        $cp.pl ~= $padding;
                        $cp.wl += ($style.padding-char.width * ($padding-count div 2));
                        $str   ~= $line;
                        $cp.pr ~= $padding;
                        $cp.wr += ($style.padding-char.width * ($padding-count div 2));
                        $cp.pr ~= ($padding-count %% 2 ?? "" !! $style.padding-char);
                        $cp.wr += ($padding-count %% 2 ?? 0 !! $style.padding-char.width);
                    } elsif $style.align-left {
                        my $padding = $style.padding-char x $padding-count;
                        $str ~= $line;
                        $cp.pr ~= $padding;
                        $cp.wr += ($style.padding-char.width * $padding-count);
                    } elsif $style.align-right {
                        my $padding = $style.padding-char x $padding-count;
                        $cp.pl ~= $padding;
                        $cp.wl += ($style.padding-char.width * $padding-count);
                        $str ~= $line;
                    } else {
                        X::Kinoko::Error.new(msg => 'Can not recognize align type!').throw();
                    }
                    [$str, $cp]
                }
            )
        }
        # style will apply to corresponding line, extra Str will use the last style
        my @new-data = Array.new;
        my @new-padding = Array.new;
        for ^+@temp -> $i {
            @new-data.push(
                String.new(
                    value => @temp[$i].[0],
                    style => $i < +@!lines ?? @!lines[$i].style !! @!lines[* - 1].style
                )
            );
            @new-padding.push(@temp[$i].[1].clone());
        }
        self.new-from-string-array-padding(@new-data, @new-padding);
    }

    method align-padding($width, $style) {
        #- table column max width = <- alinged string ->
        my $real-width = $width;
        my @lines = wrap(@!lines, :tabstop(tabstop()), :max-width($real-width), :force($style.split-word));
        my @new-padding = Array.new;
        for @lines -> $line {
            my $padding-width = $real-width - $line.width;
            unless $padding-width %% $style.padding-char.width {
                X::Kinoko::Error.new(msg => 'padding width must be divides by padding-char width').throw();
            }
            my $padding-count = $padding-width div $style.padding-char.width;
            @new-padding.push(
                do {
                    my Content::Padding $cp .= new;
                    $cp.pl ~= ($style.padding-char x $style.padding-left);
                    $cp.wl += ($style.padding-char.width * $style.padding-left);
                    if $style.align-middle {
                        my $padding = $style.padding-char x ($padding-count div 2);
                        $cp.pl ~= $padding;
                        $cp.wl += ($style.padding-char.width * ($padding-count div 2));
                        $cp.pr ~= $padding;
                        $cp.wr += ($style.padding-char.width * ($padding-count div 2));
                        $cp.pr ~= ($padding-count %% 2 ?? "" !! $style.padding-char);
                        $cp.wr += ($padding-count %% 2 ?? 0 !! $style.padding-char.width);
                    } elsif $style.align-left {
                        my $padding = $style.padding-char x $padding-count;
                        $cp.pr ~= $padding;
                        $cp.wr += ($style.padding-char.width * $padding-count);
                    } elsif $style.align-right {
                        my $padding = $style.padding-char x $padding-count;
                        $cp.pl ~= $padding;
                        $cp.wl += ($style.padding-char.width * $padding-count);
                    } else {
                        X::Kinoko::Error.new(msg => 'Can not recognize align type!').throw();
                    }
                    $cp.pr = $cp.pr ~ ($style.padding-char x $style.padding-right);
                    $cp.wr = $cp.wr + ($style.padding-char.width * $style.padding-right);
                    $cp;
                }
            )
        }
        # style will apply to corresponding line, extra Str will use the last style
        for ^+@lines -> $i {
            @lines[$i].set-style($i < +@!lines ?? @!lines[$i].style !! @!lines[* - 1].style);
        }
        self.new-from-string-array-padding(@lines, @new-padding);
    }

    method padding($style) {
        my @new-padding = Array.new;
        for @!padding -> $p {
            $p.pl = ($style.padding-char x $style.padding-left) ~ $p.pl;
            $p.wl = $p.wl + ($style.padding-char.width * $style.padding-left);
            $p.pr = $p.pr ~ ($style.padding-char x $style.padding-right);
            $p.wr = $p.wr + ($style.padding-char.width * $style.padding-right);
            @new-padding.push($p.clone());
        }
        self.new-from-string-array-padding(@!lines, @new-padding);
    }

    method extend-v(Int $h) {
        my @temp = @!lines;
        for self.height() ...^ $h {
            @temp.push(String.new(value => (' ' x self.max-width())));
        }
        self.new-from-string-array-padding(@temp, @!padding);
    }

    method clone() {
        self.bless(lines => @!lines.clone(), padding => @!padding.clone());
    }

    method height() {
        +@!lines;
    }

    method max-width() {
        my @widths = @!lines>>.width;
        for ^+@!padding {
            @widths[$_] += @!padding[$_].width();
        }
        max(@widths);
    }

    method elems() {
        @!lines.elems;
    }

    method Int() {
        @!lines.elems;
    }

    method colour(Int $index, $style) {
        @!lines[$index].set-style($style);
    }

    method get-line(Int $i) {
        @!padding[$i].defined ??
        ( @!padding[$i].pl, @!lines[$i], @!padding[$i].pr ) !!
        ("", @!lines[$i], "")
    }
}
