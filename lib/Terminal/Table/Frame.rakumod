
use v6;
use Terminal::Table::String;
use Terminal::Table::Settings;
use Terminal::Table::LightWrap;
use Terminal::Table::Exception;

enum Visibility <<
    :VTRUE(1)
    :VFALSE(3)
    :VSPACE(4)
>>;

role Visible {
    has $.visibility = Visibility::VTRUE;

    method check-visibility($visibility = Visibility::VTRUE) {
        $!visibility == $visibility;
    }

    method hide(:$replace-with-space) {
        $!visibility = ?$replace-with-space ??
            Visibility::VSPACE !! Visibility::VFALSE;
    }

    method unhide() {
        $!visibility = Visibility::VTRUE;
    }

    method clone(*%_) {
        nextwith(
            visibility => %_<visibility> // $!visibility,
            |%_
        );
    }
}

class Line {
    also does Visible;
    also does ToWhiteSpace;

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
        return self.clone() if $width <= 1;
        unless $width %% $!base.width {
            X::Kinoko::Error.new(msg => 'width must be integer multiple of base width.')
            .throw();
        }
        self.new(base => $!base.clone(), n => ($width div $!base.width) * ($v ?? -1 !! 1));
    }

    method clone(*%_) {
        nextwith(
            base => %_<base> // $!base.clone(),
            n    => %_<n> // $!n,
            |%_
        );
    }

    method raku() {
        return self.defined ?? "Line.new(base => \"{$!base.raku}\", n => $!n)" !! "(Line)";
    }
}

class Corner {
    also does Visible;
    also does ToWhiteSpace;

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

    method clone(*%_) {
        nextwith(
            base => %_<base>:exists ?? %_<base> !! $!base.clone(),
            |%_
        );
    }

    method raku() {
        return self.defined ?? "Corner.new(base => \"{$!base.raku}\")" !! "(Corner)";
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
    also does ToWhiteSpace;
    also does Visible;

    my class Content::Padding {
        has $.pl is rw = "";
        has $.wl is rw = 0;
        has $.pr is rw = "";
        has $.wr is rw = 0;

        method clone() {
            return self.bless(:$!wl, :$!wr, pl => $!pl.clone(), pr => $!pr.clone());
        }

        method width() {
            $!wl + $!wr;
        }
    }

    has @.padding;
    has @.lines handles < AT-POS ASSIGN-POS >;

    multi method new(*%args) {
        self.bless(|%args);
        nextsame;
    }

    multi method new(String $str) {
        self.bless(lines => $str.lines());
    }

    method new-from-str(Str $str) {
        self.bless()!__make_lines([$str]);
    }

    method new-from-str-array(@lines) {
        self.bless()!__make_lines(@lines);
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
        self.clone(lines => @new-data, padding => @new-padding);
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
        self.clone(:@lines, padding => @new-padding);
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
        self.clone(padding => @new-padding);
    }

    method extend-v(Int $h) {
        my @temp = @!lines;
        for self.height() ...^ $h {
            @temp.push(String.new(value => "").extend-to(self.max-width()));
        }
        self.clone(lines => @temp);
    }

    method clone(*%_) {
        nextwith(
            lines => %_<lines> // @!lines.clone(),
            padding => %_<padding> // @!padding.clone(),
            |%_
        );
    }

    method height() {
        +@!lines;
    }

    method width() {
        self.max-width();
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

    multi method colour($style) {
        .set-style($style) for @!lines;
    }

    multi method colour(Int $index, $style) {
        @!lines[$index].set-style($style);
    }

    method get-line(Int $i) {
        @!padding[$i].defined ??
        ( @!padding[$i].pl, @!lines[$i], @!padding[$i].pr ) !!
        ("", @!lines[$i], "")
    }
}
