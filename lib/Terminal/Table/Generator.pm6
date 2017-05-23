
use v6;
use Terminal::Table::Shader;
use Terminal::Table::String;
use Terminal::Table::Style;
use Terminal::Table::Frame;
use Terminal::Table::Settings;
use Terminal::Table::Exception;
use Terminal::Table::VisitorHelper;

my $init-now = INIT now;

class CellRef { ... };
class Generator { ... };
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
            Content.new(
                lines => to-string-array(@lines, $style)
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

class Generator::Table {
    has @.sc;
    has @.content;
    has @.frame;
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

    # generte max width of every column
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
                my $height = max([ .height for @oneline ]);

                # save max height for every line
                @!max-heights.push($height);
                # add empty for which little than max height
                for @oneline -> $content {
                    @!content[$index].push(
                        $content.height < $height ??
                        $content.extend-v($height) !! $content
                    );
                }
                if $style.line.is-none() {
                    # when style is NONE
                    # ignore hframe and vframe
                    # pass only content array to callback
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

                for 0 ..^ +@!content[$index] -> $cindex {
                    my \hline  = $cache.hline($cindex, @!max-widths[$cindex]);
                    my \corner = $cache.corner();
                    # add a cell to frame
                    # current a cell mean
                    # --+
                    #  |
                    # i.e
                    # top line
                    # top right corner
                    # right line
                    self!__add_cell(
                        $cache.vline($index, $height).middle(),
                        $index == 0 ?? hline.top() !! hline.middle(),
                        ($index == 0 || $cindex >= @!content[$index - 1].elems) ??
                            corner.top().middle() !! corner.middle().middle()
                    );
                }
                # when last line is longer than current line
                my $last-minus-current = $index <= 0 ?? -1 !!
                    @!content[$index - 1].elems - @!content[$index].elems;

                # end current line i.e. complete current frame array
                # add top left corner
                # add far left line
                # add far right line
                # and when last-minus-current > -1
                # add rest cell
                # replace corner
                self!__end_line(
                    $height,
                    @!max-widths,
                    @!content[$index].elems,
                    $cache,
                    $index,
                    $last-minus-current
                );
                # call callback with
                # hframe
                # vfreame
                # content
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
            # insert last hframe
            self!__insert_last_line(
                @!max-widths,
                @!style[* - 1].cache,
                +@!content[* - 1]
            );
            # call callback with last hframe
            # with no vframe, no content
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

    method !__reset() {
        if $!index > 0 {
            @!content = Array.new;
            @!frame = Array.new;
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

    method Int {
        +@!content;
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

    multi method colour(Int $r, Int $c, Color::String $style, Int $row = 0) {
        @!content[$r][$c].colour($row, $style);
        self;
    }

    multi method colour(Int $r, Int $c, Color::String $style) {
        @!content[$r][$c].colour($style);
        self;
    }

    multi method colour(Int $index, Color::String $style, :$v) {
        if ?$v {
            for @!content -> $cl {
                $cl.[$index].colour($style) if $index < $cl.elems;
            }
        } else {
            .colour($style) for @!content[$index];
        }
    }

    # [ + -- + -- + ]
    # [ |    |    | ]
    # [ + -- + -- + ]
    # [ |    |    | ]
    # [ + -- + -- + ]
    # Frame data is store in above 2d-array form
    # [  xx    xx   ]
    # [  xx    xx   ]
    # Content data is store in above 2d-array form
    # top-left    top   top-right
    #         + ------- +
    #    left | content | right
    #        + ------- +
    #bottom-left bottom bottom-right
    # A cell has 4 corner, 4 line, 1 content
    # Access corner/line with their direction
    method !__ref_a_cell(Int $r, Int $c) {
        my \fr = @!frame;
        my \cr = @!content;
        return CellRef.new(frameref => fr, contentref => cr, :$r, :$c);
    }

    multi method cell(Int $r, Int $c) {
        return self!__ref_a_cell($r, $c);
    }

    multi method cell(WhateverCode $wc, Int $c) {
        return self!__ref_a_cell($wc.(self.row-count()), $c);
    }

    multi method cell(Int $r, WhateverCode $wc) {
        return self!__ref_a_cell($r, $wc.(self.col-count($r)));
    }

    multi method cell(WhateverCode $wcr, WhateverCode $wcc) {
        my $r = $wcr.(self.row-count());
        my $c = $wcc.(self.col-count($r));
        return self!__ref_a_cell($r, $c);
    }

    # [ + -- + -- + ]
    # [ | xx | xx | ]
    # [ + -- + -- + ]
    # [ | xx | xx | ]
    # [ + -- + -- + ]
    # hide operator on result table
    multi method hide(WhateverCode $wc, :$v, :$replace-with-space) {
        my $max = ?$v ?? self.max-col-count() !! self.row-count();
        self.hide($wc.($max * 2 + 1), :$v, :$replace-with-space);
        self;
    }

    multi method hide(Int $index, :$v, :$replace-with-space) {
        if ?$v {
            if $index % 2 == 1  {
                for ^self.row-count() -> $row {
                    if $index < @!frame[$row * 2].elems {
                        @!frame[$row * 2][$index].hide(:$replace-with-space);
                        @!content[$row][($index - 1) div 2].hide(:$replace-with-space);
                    }
                }
            } else {
                for ^self.row-count() -> $row {
                    if $index < @!frame[$row * 2].elems {
                        @!frame[$row * 2][$index].hide(:$replace-with-space);
                        @!frame[$row * 2 + 1][$index div 2].hide(:$replace-with-space);
                    }
                }
            }
        } else {
            if $index % 2 == 1 {
                .hide(:$replace-with-space) for @(@!content[($index - 1) div 2]);
            }
            .hide(:$replace-with-space) for @(@!frame[$index]);
        }
        self;
    }

    multi method hide(Int $r, Int $c, :$replace-with-space) {
        my $f-or-c = ($r % 2 == 1) ?? (
            $c % 2 == 1 ?? @!content[($r - 1) div 2][($c - 1) div 2] !! @!frame[$r][$c div 2]
        ) !! @!frame[$r][$c];
        $f-or-c.hide(:$replace-with-space);
        self;
    }

    multi method hide(WhateverCode $wc, Int $c, :$replace-with-space) {
        my $r = $wc.(self.row-count() * 2  + 1);
        my $f-or-c = ($r % 2 == 1) ?? (
            $c % 2 == 1 ?? @!content[($r - 1) div 2][($c - 1) div 2] !! @!frame[$r][$c div 2]
        ) !! @!frame[$r][$c];
        $f-or-c.hide(:$replace-with-space);
        self;
    }

    multi method hide(Int $r, WhateverCode $wc, :$replace-with-space) {
        my $c = $wc.(self.max-col-count() * 2  + 1);
        my $f-or-c = ($r % 2 == 1) ?? (
            $c % 2 == 1 ?? @!content[($r - 1) div 2][($c - 1) div 2] !! @!frame[$r][$c div 2]
        ) !! @!frame[$r][$c];
        $f-or-c.hide(:$replace-with-space);
        self;
    }

    multi method hide(WhateverCode $wcr, WhateverCode $wcc, :$replace-with-space) {
        my $r = $wcr.(self.row-count() * 2  + 1);
        my $c = $wcc.(self.max-col-count() * 2  + 1);
        my $f-or-c = ($r % 2 == 1) ?? (
            $c % 2 == 1 ?? @!content[($r - 1) div 2][($c - 1) div 2] !! @!frame[$r][$c div 2]
        ) !! @!frame[$r][$c];
        $f-or-c.hide(:$replace-with-space);
        self;
    }

    multi method unhide(WhateverCode $wc, :$v) {
        my $max = ?$v ?? self.max-col-count() !! self.row-count();
        self.unhide($wc.($max * 2 + 1), :$v);
        self;
    }

    multi method unhide(Int $index, :$v) {
        if ?$v {
            if $index % 2 == 1  {
                for ^self.row-count() -> $row {
                    if $index < @!frame[$row * 2].elems {
                        @!frame[$row * 2][$index].unhide();
                        @!content[$row][($index - 1) div 2].unhide();
                    }
                }
            } else {
                for ^self.row-count() -> $row {
                    if $index < @!frame[$row * 2].elems {
                        @!frame[$row * 2][$index].unhide();
                        @!frame[$row * 2 + 1][$index div 2].unhide();
                    }
                }
            }
        } else {
            if $index % 2 == 1 {
                .unhide() for @(@!content[($index - 1) div 2]);
            }
            .unhide() for @(@!frame[$index]);
        }
        self;
    }

    multi method unhide(Int $r, Int $c) {
        my $f-or-c = ($r % 2 == 1) ?? (
            $c % 2 == 1 ?? @!content[($r - 1) div 2][($c - 1) div 2] !! @!frame[$r][$c div 2]
        ) !! @!frame[$r][$c];
        $f-or-c.unhide();
        self;
    }

    multi method unhide(WhateverCode $wc, Int $c) {
        my $r = $wc.(self.row-count() * 2  + 1);
        my $f-or-c = ($r % 2 == 1) ?? (
            $c % 2 == 1 ?? @!content[($r - 1) div 2][($c - 1) div 2] !! @!frame[$r][$c div 2]
        ) !! @!frame[$r][$c];
        $f-or-c.unhide();
        self;
    }

    multi method unhide(Int $r, WhateverCode $wc) {
        my $c = $wc.(self.max-col-count() * 2  + 1);
        my $f-or-c = ($r % 2 == 1) ?? (
            $c % 2 == 1 ?? @!content[($r - 1) div 2][($c - 1) div 2] !! @!frame[$r][$c div 2]
        ) !! @!frame[$r][$c];
        $f-or-c.unhide();
        self;
    }

    multi method unhide(WhateverCode $wcr, WhateverCode $wcc) {
        my $r = $wcr.(self.row-count() * 2  + 1);
        my $c = $wcc.(self.max-col-count() * 2  + 1);
        my $f-or-c = ($r % 2 == 1) ?? (
            $c % 2 == 1 ?? @!content[($r - 1) div 2][($c - 1) div 2] !! @!frame[$r][$c div 2]
        ) !! @!frame[$r][$c];
        $f-or-c.unhide();
        self;
    }

    multi method is-hidden(Int $r, Int $c) {
        my $f-or-c = ($r % 2 == 1) ?? (
            $c % 2 == 1 ?? @!content[($r - 1) div 2][($c - 1) div 2] !! @!frame[$r][$c div 2]
        ) !! @!frame[$r][$c];
        !$f-or-c.check-visibility(Visibility::VTRUE);
    }

    multi method is-hidden(WhateverCode $wc, Int $c) {
        my $r = $wc.(self.row-count() * 2  + 1);
        my $f-or-c = ($r % 2 == 1) ?? (
            $c % 2 == 1 ?? @!content[($r - 1) div 2][($c - 1) div 2] !! @!frame[$r][$c div 2]
        ) !! @!frame[$r][$c];
        !$f-or-c.check-visibility(Visibility::VTRUE);
    }

    multi method is-hidden(Int $r, WhateverCode $wc) {
        my $c = $wc.(self.max-col-count() * 2  + 1);
        my $f-or-c = ($r % 2 == 1) ?? (
            $c % 2 == 1 ?? @!content[($r - 1) div 2][($c - 1) div 2] !! @!frame[$r][$c div 2]
        ) !! @!frame[$r][$c];
        !$f-or-c.check-visibility(Visibility::VTRUE);
    }

    multi method is-hidden(WhateverCode $wcr, WhateverCode $wcc) {
        my $r = $wcr.(self.row-count() * 2  + 1);
        my $c = $wcc.(self.max-col-count() * 2  + 1);
        my $f-or-c = ($r % 2 == 1) ?? (
            $c % 2 == 1 ?? @!content[($r - 1) div 2][($c - 1) div 2] !! @!frame[$r][$c div 2]
        ) !! @!frame[$r][$c];
        !$f-or-c.check-visibility(Visibility::VTRUE);
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
            @table.push(@t) unless +@t == 0;
        };
        my &v-frame = sub (|c) {
            for @($helper.v-frame(|c)) -> $line {
                my @t = Array.new;
                @t.push($_) for @($line);
                @table.push(@t) unless +@t == 0;
            }
        };

        self.visit(:&h-frame, :&v-frame, $coloured);

        return @table;
    }

    method print(Bool :$coloured = False, :$helper = &visitor-helper()) {
        my &h-frame = sub (|c) {
            my @line = @($helper.h-frame(|c));
            unless +@line == 0 {
                .print for @line;
                "".say;
            }
        };
        my &v-frame = sub (|c) {
            for @($helper.v-frame(|c)) -> $line {
                unless +@$line == 0 {
                    .print for @($line);
                    "".say;
                }
            }
        };

        self.visit(:&h-frame, :&v-frame, $coloured);
    }

    method visit(Bool $coloured = True, :&h-frame, :&v-frame) {
        for @!style -> $style {
            for $style.beg .. $style.end -> $index {
                if $style.style.line.is-none() {
                    &v-frame([], @!content[$index], $coloured);
                } else {
                    my $findex = $index * 2;
                    if ?&h-frame {
                        &h-frame(@!frame[$findex], $coloured);
                    }
                    if ?&v-frame {
                        &v-frame(@!frame[$findex + 1], @!content[$index], $coloured);
                    }
                }
            }
        }
        if ?&h-frame && !@!style[* - 1].style.line.is-none() {
            &h-frame(@!frame[* - 1], $coloured);
        }
    }
}

class Generator::StyleCache {
    has $.style;
    has @!hline = Array.new;
    has @!vline = Array.new;
    has $!corner;

    my $using-cache = &style-cache();

    sub make-and-get-cache(\cache, &make-cache) {
        $using-cache ?? (
            return cache // do {
                cache = &make-cache();
                cache;
            };
        ) !! (
            cache ?? cache.clone() !! do {
                cache = &make-cache();
                cache;
            }
        )
    }

    method hline(Int $col, Int $width) {
        return @!hline[$col] || do {
            @!hline[$col] = class :: {
                has $.style;
                has $.width;
                has $!top;
                has $!middle;
                has $!bottom;

                method top() {
                    return &make-and-get-cache($!top, -> {
                        $!style.line.top.extend-to($!width);
                    });
                }

                method middle() {
                    return &make-and-get-cache($!middle, -> {
                        $!style.line.h-middle.extend-to($!width);
                    });
                }

                method bottom() {
                    return &make-and-get-cache($!bottom, -> {
                        $!style.line.bottom.extend-to($!width);
                    });
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
                    return &make-and-get-cache($!left, -> {
                        $!style.line.left.extend-to($!height, :v);
                    });
                }

                method middle() {
                    return &make-and-get-cache($!middle, -> {
                        $!style.line.v-middle.extend-to($!height, :v);
                    });
                }

                method right() {
                    return &make-and-get-cache($!right, -> {
                        $!style.line.right.extend-to($!height, :v);
                    });
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
                    return &make-and-get-cache(@!array[0], -> {
                        $!style.left.clone();
                    });
                }

                method middle {
                    return &make-and-get-cache(@!array[1], -> {
                        $!style.middle.clone();
                    });
                }

                method right {
                    return &make-and-get-cache(@!array[2], -> {
                        $!style.right.clone();
                    });
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

class CellRef {
    has $.frameref;
    has $.contentref;
    has $.r;
    has $.c;

    method content() {
        return $!contentref.[$!r][$!c];
    }

    method corner() {
        return class :: {
            has $.frameref;
            has $.r;
            has $.c;

            method top-left() {
                return $!frameref.[$!r * 2][$!c * 2];
            }

            method top-right() {
                return $!frameref.[$!r * 2][($!c + 1) * 2];
            }

            method bottom-left() {
                return $!frameref.[($!r + 1) * 2][$!c * 2];
            }

            method bottom-right() {
                return $!frameref.[($!r + 1) * 2][($!c + 1) * 2];
            }
        }.new(:$!r, :$!c, :$!frameref);
    }

    method line() {
        return class :: {
            has $.frameref;
            has $.r;
            has $.c;

            method top() {
                return $!frameref.[$!r * 2][$!c * 2 + 1];
            }

            method left() {
                return $!frameref.[$!r * 2 + 1][$!c * 2];
            }

            method right() {
                return $!frameref.[$!r * 2 + 1][($!c + 1) * 2];
            }

            method bottom() {
                return $!frameref.[($!r + 1) * 2][$!c * 2 + 1];
            }
        }.new(:$!r, :$!c, :$!frameref);
    }
}
