
use v6;
use Terminal::Table::Shader;
use Terminal::Table::String;
use Terminal::Table::Style;
use Terminal::Table::Frame;
use Terminal::Table::Settings;
use Terminal::Table::Exception;

my $init-now = INIT now;

class Generator::StyleCache { ... };

class Generator {
    my class ScopeStyle {
        has Int $.beg is rw;
        has Int $.end is rw;
        has     $.style;
        has     $.cache;

        submethod TWEAK(:$style) {
            $!cache = Generator::StyleCache.new(
                style => $style
            );
        }
    }

    has @.data;
    has @.style;
    has $!index = 0;

    method new(Style :$style! is copy) {
        self.bless(style => [ ScopeStyle.new(beg => 0, style => $style), ]);
    }

    multi sub make-string(Str $str) {
        if Shader.has-color($str) {
            my $str-style = Shader.extract-style($str);
            if $str-style !~~ "" {
                my $style = Color::String.new(color => $str-style.split(/\s+/, :skip-empty));
                return String.new(value => Shader.wipe-style($str), :$style);
            }
        }
        return String.new(value => $str);
    }

    multi sub make-string(Str $str, $style) {
        if Shader.has-color($str) {
            my $str-style = Shader.extract-style($str);
            if $str-style !~~ "" {
                if $style.defined {
                    $style.append($str-style.split(/\s+/, :skip-empty));
                } else {
                    $style = Color::String.new(color => $str-style.split(/\s+/, :skip-empty));
                }
                String.new(value => Shader.wipe-style($str), :$style);
            }
        }
        return String.new(value => $str, :$style);
    }

    multi method add-cell(Str $str, Color::String $style) {
        @!data[$!index].push(
            Content.new(
                make-string($str, $style)
            )
        );
        self;
    }

    multi method add-cell(Str $str) {
        @!data[$!index].push(
            Content.new(
                make-string($str)
            )
        );
        self;
    }

    multi method add-cell(@lines) {
        @!data[$!index].push(
            Content.new-from-str-array( -> {
                my @t = Array.new;
                @t.push(make-string($_)) for @lines;
                @t;
            }())
        );
        self;
    }

    sub to-string-array(@lines, $style) {
        my @ret = Array.new;
        @ret.push(make-string($_, $style)) for @lines;
        @ret;
    }

    multi method add-cell(@lines, Color::String $style) {
        @!data[$!index].push(
            Content.new-from-string-array(
                to-string-array(@lines, $style)
            )
        );
        self;
    }

    multi method add-cell($maybestr where * !~~ Str) {
        @!data[$!index].push(
            Content.new(
                make-string($maybestr.Str())
            )
        );
        self;
    }

    multi method add-cell($maybestr where * !~~ Str, Color::String $style) {
        @!data[$!index].push(
            Content.new(
                make-string($maybestr.Str(), $style)
            )
        );
        self;
    }

    method end-line() {
        $!index++;
        self;
    }

    multi method from-array(@array) {
        for @array -> $inner_array {
            my @t = Array.new;
            @t.push(Content.new(
                String.new(value => $_)
            )) for @$inner_array;
            @!data.push(@t);
            self.end-line();
        }
        self;
    }

    multi method from-array(@array, @styles) {
        for @array Z, @styles -> ($inner_array, $inner_style) {
            my @t = Array.new;
            for @$inner_array Z, @$inner_style -> ($str, $style) {
                @t.push(Content.new(
                    String.new(value => $str, :$style)
                ));
            }
            @!data.push(@t);
            self.end-line();
        }
        self;
    }

    method !__last_row_not_empty() {
        @!data[$!index].defined && @!data[$!index].elems > 0;
    }

    method !__join(@array) {
        self.end-line() if self!__last_row_not_empty();

        for @array -> $inner-array {
            if $inner-array.elems > 0 {
                @!data[$!index].push(.clone()) for @$inner-array;
                self.end-line();
            }
        }
        self;
    }

    method join(Generator $g, :$preserve-style, :$replace-style) {
        if $preserve-style {
            my \last-style = @!style[* - 1];
            last-style.end = self!__last_row_not_empty()
                ?? -> { self.end-line(); $!index; }() !! $!index - 1;
            my @g-style := $g.style;

            for @g-style -> $style {
                @!style.push(ScopeStyle.new(
                    beg   => last-style.end + $style.beg + 1,
                    style => $style.style.clone()
                ));
                @!style[* - 1].end = $style.end + last-style.end + 1
                    if $style.end.defined;
            }
            unless [+^] [ .style.line.is-none() for @!style ] {
                X::Kinoko::Error.new(msg => 'All style should be none!')
                .throw();
            }
        }
        if $replace-style {
            if $g.style.[* - 1].beg > $!index {
                X::Kinoko::Error.new(msg => 'The style-end is bigger than current index.')
                .throw();
            }
            @!style = $g.style.clone();
        }
        self!__join($g.data);
    }

    method generator(:&callback) {
        my @style = @!style.clone();

        @style[* - 1].end = self!__last_row_not_empty() ?? $!index !! $!index - 1;

        note "{&?ROUTINE}:\t\n{now - $init-now}" if debug();

        class Generator::Table { ... };

        my $gt = Generator::Table.new(@!data.clone(), @style);

        $gt.set-callback(&callback) if ?&callback;

        return $gt;
    }

    method perl() {
        self.defined ?? "Generator.new(style => {@!style[0].style.pelr})" !! "(Generator)";
    }
}

class Generator::VisitorHelper {
    has %.callback-map;

    method __check_callback_map($name) {
        unless %!callback-map{$name}:exists {
            %!callback-map{$name} = Array.new;
        }
    }

    method add-helper(Str $name, &callback) {
        self.__check_callback_map($name);
		%!callback-map{$name}.push(&callback);
    }

	method FALLBACK($name, |c) {
		for @(%!callback-map{$name}) -> &cb {
			if c ~~ &cb.signature {
                return &cb(|c);
            }
		}
        fail "Not wrapper named: $name with signature {c.perl}!";
	}
}

sub visitor-helper() returns Generator::VisitorHelper is export is rw {
    state $helper = Generator::VisitorHelper.new;

    $helper.add-helper("colour",
    sub ($s, Bool $coloured) {
        return $s.Str();
    });
    $helper.add-helper("colour",
    sub ($pleft, String $s, $pright, Bool $coloured)  {
        return $pleft ~ (
            ?$coloured && $s.coloured() ??
            Shader.colour($s.Str(), $s.style()) !! $s.Str()
        ) ~ $pright;
    });
    $helper.add-helper("h-frame",
    sub (@h-frame, @v-frame-visibility, Bool $coloured) {
        return lazy gather for @h-frame Z, @v-frame-visibility -> ($f, $v) {
            take &visitor-helper().colour($f, $coloured) if $v;
        };
    });
    $helper.add-helper("h-frame",
    sub (@h-frame, Bool $coloured) {
        return lazy gather for @h-frame -> $f {
            take &visitor-helper().colour($f, $coloured);
        };
    });
    $helper.add-helper("v-frame",
    sub (@v-frame, @contents, @v-frame-visibility, Bool $coloured){
        my @ret = [];
        if +@v-frame > 0 && +@contents > 0 {
            for ^@contents[0].height -> $row {
                @ret.push(
                    lazy gather {
                        for (@v-frame Z, @contents).flat Z, @v-frame-visibility -> ($f-or-c, $v) {
                            take &visitor-helper().colour(| $f-or-c.get-line($row), $coloured) if $v;
                        }
                        take &visitor-helper().colour(|@v-frame[* - 1].get-line($row), $coloured)
                            if @v-frame-visibility[* - 1];
                    }
                );
            }
        } elsif +@contents > 0 { #`( v-frame will be empty when style is none)
            for ^@contents[0].height -> $row {
                @ret.push(lazy gather {
                    for @contents -> $c {
                        take &visitor-helper().colour(| $c.get-line($row), $coloured);
                    }
                });
            }
        }
        return @ret;
    });
    $helper.add-helper("v-frame",
    sub (@v-frame, @contents, Bool $coloured){
        my @ret = [];
        if +@v-frame > 0 && +@contents > 0 {
            for ^@contents[0].height -> $row {
                @ret.push(
                    lazy gather {
                        for (@v-frame Z, @contents).flat -> $f-or-c {
                            take &visitor-helper().colour(| $f-or-c.get-line($row), $coloured);
                        }
                        take &visitor-helper().colour(|@v-frame[* - 1].get-line($row), $coloured);
                    }
                );
            }
        } elsif +@contents > 0 { #`( v-frame will be empty when style is none)
            for ^@contents[0].height -> $row {
                @ret.push(
                    lazy gather {
                        for @contents -> $c {
                            take &visitor-helper().colour(| $c.get-line($row), $coloured);
                        }
                    }
                );
            }
        }
        return @ret;
    });
    $helper.add-helper("generate",
    sub (@h-frame, @v-frame, @contents, Bool $coloured) {
        my @ret = [];
        if +@h-frame > 0 {
            @ret.push(lazy gather for @h-frame -> $f {
                take &visitor-helper().colour($f, $coloured);
            });
        }
        if +@contents > 0 {
            @ret.append(
                &visitor-helper().v-frame(@v-frame, @contents, $coloured)
            );
        }
        return @ret;
    });
    $helper;
}

class Generator::Table {
    has @.sc;
    has @.content;
    has @.frame;
    has @.v-frame-visibility;
    has @.h-frame-visibility;
    has @.style;
    has @.iterator;
    has @.max-widths;
    has @.max-heights;
    has @.style-caches;
    has $.index = 0;
    has &.callback;

    method new(@sc, @style) {
        self.bless(:@sc, :@style);
    }

    method !__gen_max_widths(@max-widths) {
        @!max-widths = 0 xx [ .elems for @!sc ].max;
        @!max-widths[0 .. +@max-widths - 1] = @max-widths if +@max-widths > 0;
        for @!sc -> $line {
            for ^$line.elems -> $index {
                unless @max-widths[$index].defined && @max-widths[$index] != -1 {
                    if $line.[$index].max-width > @!max-widths[$index] {
                        @!max-widths[$index] = $line.[$index].max-width;
                    }
                }
            }
        }
        my Int $align = 0;
        for @!style -> $style {
            $align = $style.style.content.padding-width
                if $align < $style.style.content.padding-width;
        }
        @!max-widths = @!max-widths.map: { $_ + $align };
    }

    method !__gen_one_line($style, $index) {
        return lazy gather for @(@!sc[$index]) Z, @!max-widths -> ($content, $width) {
            take $content.align-padding(
                $width - $style.content.padding-width, $style.content
            );
        }
    }

    method !__gen_frame_and_content(Bool $coloured) {
        for @!style -> $scope-style {
            for $scope-style.beg .. $scope-style.end -> $index {
                my $style := $scope-style.style;
                my @oneline = self!__gen_one_line($style, $index);

                if $style.line.is-none() {
                    @!content[$index].append(@oneline);
                    &!callback(
                        [],
                        [],
                        @!content[$index],
                        $coloured
                    ) if ?&!callback;
                    next;
                }
                self!__gen_iterator();
                my $cache  = $scope-style.cache;
                my $height = max([ .height for @oneline ]);

                @!max-heights.push($height);
                for @oneline -> $content {
                    @!content[$index].push(
                        $content.height < $height ??
                        $content.extend-v($height) !! $content
                    );
                }
                for 0 ..^ +@!content[$index] -> $cindex {
                    my \hline  = $cache.hline($cindex, @!max-widths[$cindex]);
                    my \corner = $cache.corner();
                    self!__add_cell(
                        $cache.vline($index, $height).middle(),
                        $index == 0 ?? hline.top() !! hline.middle(),
                        ($index == 0 || $cindex >= @!content[$index - 1].elems) ??
                            corner.top().middle() !! corner.middle().middle()
                    );
                }
                my $last-minus-current = $index <= 0 ?? -1 !!
                    @!content[$index - 1].elems - @!content[$index].elems;
                self!__end_line(
                    $height,
                    @!max-widths,
                    @!content[$index].elems,
                    $cache,
                    $index,
                    $last-minus-current
                );
                &!callback(
                    @!iterator[0],
                    @!iterator[1],
                    @!content[$index],
                    $coloured
                ) if ?&!callback;
                self!__incrment_index();
            }
        }
        unless @!style[* - 1].style.line.is-none() {
            self!__insert_last_line(
                @!max-widths,
                @!style[* - 1].cache,
                +@!content[* - 1]
            );
            &!callback(
                @!frame[$!index],
                [],
                [],
                $coloured
            ) if ?&!callback;
        }
    }

    method !__gen_iterator() {
        @!frame[$!index] = Array.new;
        @!frame[$!index + 1] = Array.new;
        @!iterator[0] := @!frame[$!index];
        @!iterator[1] := @!frame[$!index + 1];
    }

    method !__add_cell($vline, $hline, $corner) {
        @!iterator[1].push($vline);
        @!iterator[0].push($hline);
        @!iterator[0].push($corner);
    }

    method !__incrment_index() {
        $!index += 2;
    }

    method !__end_line($height, @max-widths, $elems, $cache, $index, $spare) {
        my \corner = $cache.corner();
        my \vline  = $cache.vline($index, $height);

        @!iterator[0].unshift(
            $index == 0 ??
            corner.top().left() !! corner.middle().left()
        );
        @!iterator[1].unshift(vline.left());
        if $spare > -1 {
            @!iterator[0][* - 1] = corner.middle().middle()
                if $spare > 0;
            @!iterator[0].append(
                $cache.hline($elems + $_, @max-widths[$_ + $elems]).middle(),
                corner.bottom().middle()
            ) for ^$spare;
            @!iterator[0][* - 1] = $spare == 0 ??
                corner.middle().right() !! corner.bottom().right();
        } else {
            @!iterator[0][* - 1] = corner.top().right();
        }
        @!iterator[1][* - 1] = vline.right();
    }

    method !__insert_last_line(@max-widths, $cache, $spare) {
        my $last-index = $!index;
        @!frame[$last-index] = Array.new;
        @!frame[$last-index].push($cache.corner().bottom().left());
        @!frame[$last-index].append(
            $cache.hline($_, @max-widths[$_]).bottom(),
            $cache.corner().bottom().middle()
        ) for ^$spare;
        @!frame[$last-index][* - 1] = $cache.corner().bottom().right();
    }

    method !__gen_frame_visibility() {
        # the frame-visibility about result table
        unless @!style[* - 1].style.line.is-none() {
            @!v-frame-visibility = True xx (max(@!content>>.elems) * 2 + 1);
            @!h-frame-visibility = True xx (+@!content * 2 + 1);
        }
    }

    method !__reset() {
        if $!index > 0 {
            @!content = Array.new;
            @!frame = Array.new;
            @!v-frame-visibility = Array.new;
            @!h-frame-visibility = Array.new;
            @!iterator = Array.new;;
            @!max-widths = Array.new;
            @!max-heights = Array.new;
            $!index = 0;
        }
    }

    method generate(@max-widths = [], :$coloured#`( will pass it to callback in generate process )) {
        self!__reset();
        self!__gen_max_widths(@max-widths);
        note "{&?ROUTINE}:\t\n{now - $init-now}" if debug();
        self!__gen_frame_and_content(?$coloured);
        note "{&?ROUTINE}:\t\n{now - $init-now}" if debug();
        self!__gen_frame_visibility();
        self;
    }

    method set-callback(&callback#`(:(@hframe, @vframe, @content, Bool))) {
        &!callback = &callback;
        self;
    }

    method clear-callback() {
        &!callback = Block;
        self;
    }

    method row-count() {
        +@!content;
    }

    method max-col-count() {
        max(@!content>>.elems);
    }

    method col-count(Int $index) {
        @!content[$index].elems;
    }

    multi method colour(Int $x, Int $y, Color::String $style, Int $row = 0) {
        @!content[$x][$y].colour($row, $style);
        self;
    }

    multi method colour(Int $x, Int $y, Color::String $style) {
        @!content[$x][$y].colour($_, $style) for ^@!content[$x][$y].elems;
        self;
    }

    multi method hide(WhateverCode $wc, :$v) {
        if ?$v {
            @!v-frame-visibility[$wc] = False;
        } else {
            @!h-frame-visibility[$wc] = False;
        }
        self;
    }

    multi method hide(Int $index, :$v) {
        if ?$v {
            @!v-frame-visibility[$index] = False;
        } else {
            @!h-frame-visibility[$index] = False;
        }
        self;
    }

    multi method unhide(WhateverCode $wc, :$v) {
        if ?$v {
            @!v-frame-visibility[$wc] = True;
        } else {
            @!h-frame-visibility[$wc] = True;
        }
        self;
    }

    multi method unhide(Int $index, :$v) {
        if ?$v {
            @!v-frame-visibility[$index] = True;
        } else {
            @!h-frame-visibility[$index] = True;
        }
        self;
    }

    method to-array(Bool :$coloured = False, :$helper = &visitor-helper()) {
        my @table = Array.new;
        #`(
            @h-frame represent a full horizonal-frame line
            < + ---- + ---- ... >
            @v-frame-visibility represent every column visibility
            <  True  False .... >
            @content represent a content line
            <  XYZ ZUW ... >
            @v-frame represent a vertical-frame line
            < |  |  |.... >
            @content + @v-frame = full line
        )
        my &h-frame = sub (|c) {
            my @t = Array.new;
            @t.push($_) for @($helper.h-frame(|c));
            @table.push(@t);
        };
        my &v-frame = sub (|c) {
            for @($helper.v-frame(|c)) -> $line {
                my @t = Array.new;
                @t.push($_) for @($line);
                @table.push(@t);
            }
        };

        self.visit(:&h-frame, :&v-frame, $coloured);

        return @table;
    }

    method print(Bool :$coloured = False, :$helper = &visitor-helper()) {
        my &h-frame = sub (|c) {
            .print for @($helper.h-frame(|c));
            "".say;
        };
        my &v-frame = sub (|c) {
            for @($helper.v-frame(|c)) -> $line {
                .print for @($line);
                "".say;
            }
        };

        self.visit(:&h-frame, :&v-frame, $coloured);
    }

    method visit-all(Bool $coloured = True, :&h-frame, :&v-frame) {
        for @!style -> $style {
            for $style.beg .. $style.end -> $index {
                my $findex = $index * 2;
                if !$style.style.line.is-none() && ?&h-frame {
                    &h-frame(@!frame[$findex], $coloured);
                }
                if ?&v-frame {
                    if $style.style.line.is-none() {
                        &v-frame([], @!content[$index], $coloured);
                    } else {
                        &v-frame(@!frame[$findex + 1], @!content[$index], $coloured);
                    }
                }
            }
        }
        if ?&v-frame {
            unless @!style[* - 1].style.line.is-none() {
                &h-frame(@!frame[* - 1], $coloured);
            }
        }
    }

    method visit(Bool $coloured = True, :&h-frame, :&v-frame) {
        for @!style -> $style {
            for $style.beg .. $style.end -> $index {
                my $findex = $index * 2;
                if !$style.style.line.is-none() && @!h-frame-visibility[$findex] && ?&h-frame {
                    &h-frame(@!frame[$findex], @!v-frame-visibility, $coloured);
                }
                if @!h-frame-visibility[$findex + 1] && ?&v-frame {
                    if $style.style.line.is-none() {
                        &v-frame([], @!content[$index], [], $coloured);
                    } else {
                        &v-frame(@!frame[$findex + 1], @!content[$index], @!v-frame-visibility, $coloured);
                    }
                }
            }
        }
        if @!h-frame-visibility[* - 1] && ?&v-frame {
            unless @!style[* - 1].style.line.is-none() {
                &h-frame(@!frame[* - 1], @!v-frame-visibility, $coloured);
            }
        }
    }
}

class Generator::StyleCache {
    has $.style;
    has @!hline = Array.new;
    has @!vline = Array.new;
    has $!corner;

    method hline(Int $col, Int $width) {
        return @!hline[$col] || do {
            @!hline[$col] = class :: {
                has $.style;
                has $.width;
                has $!top;
                has $!middle;
                has $!bottom;

                method top() {
                    return $!top || do {
                        $!top = $!style.line.top.extend-to($!width);
                        $!top;
                    }
                }

                method middle() {
                    return $!middle || do {
                        $!middle = $!style.line.h-middle.extend-to($!width);
                        $!middle;
                    }
                }

                method bottom() {
                    return $!bottom || do {
                        $!bottom = $!style.line.bottom.extend-to($!width);
                        $!bottom;
                    }
                }
            }.new(:$!style, :$width);
            @!hline[$col];
        }
    }

    method vline(Int $row, Int $height) {
        return @!vline[$row] || do {
            @!vline[$row] = class :: {
                has $.style;
                has $.height;
                has $!left;
                has $!middle;
                has $!right;

                method left() {
                    return $!left || do {
                        $!left = $!style.line.left.extend-to($!height, :v);
                        $!left;
                    }
                }

                method middle() {
                    return $!middle || do {
                        $!middle = $!style.line.v-middle.extend-to($!height, :v);
                        $!middle;
                    }
                }

                method right() {
                    return $!right || do {
                        $!right = $!style.line.right.extend-to($!height, :v);
                        $!right;
                    }
                }
            }.new(:$!style, :$height);
            @!vline[$row];
        }
    }

    method corner() {
        return $!corner || do {
            my class LineCache {
                has $.style;
                has @.array = Array.new;

                method new(:$style) {
                    self.bless(:$style);
                }

                method left {
                    @!array[0] || do {
                        @!array[0] = $!style.left.clone();
                        @!array[0];
                    };
                }

                method middle {
                    @!array[1] || do {
                        @!array[1] = $!style.middle.clone();
                        @!array[1];
                    };
                }

                method right {
                    @!array[2] || do {
                        @!array[2] = $!style.right.clone();
                        @!array[2];
                    };
                }
            }

            $!corner = class :: {
                has $.style;
                has @.corner = Array.new;

                method top() {
                    return @!corner[0] || do {
                        @!corner[0] = LineCache.new(
                            style => $!style.corner.top
                        );
                        @!corner[0]
                    }
                }

                method middle() {
                    return @!corner[1] || do {
                        @!corner[1] = LineCache.new(
                            style => $!style.corner.middle
                        );
                        @!corner[1]
                    }
                }

                method bottom() {
                    return @!corner[2] || do {
                        @!corner[2] = LineCache.new(
                            style => $!style.corner.bottom
                        );
                        @!corner[2]
                    }
                }
            }.new(:$!style);
            $!corner;
        }
    }
}
