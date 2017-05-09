
use v6;
use Terminal::Table::Shader;
use Terminal::Table::String;
use Terminal::Table::Style;
use Terminal::Table::Frame;
use Terminal::Table::Exception;

class Generator {
    my class ScopeStyle {
        has Int $.beg is rw;
        has Int $.end is rw;
        has     $.style;
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
        return String.new(value => $str);
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

    multi method join(@array) {
        self.end-line() if self!__last_row_not_empty();

        for @array -> $inner-array {
            if $inner-array.elems > 0 {
                @!data[$!index].push(.clone()) for @$inner-array;
                self.end-line();
            }
        }
        self;
    }

    multi method join(Generator $g, :$preserve-style, :$replace-style) {
        if $preserve-style {
            my \last-style = @!style[* - 1];
            last-style.end = self!__last_row_not_empty()
                ?? -> { self.end-line(); $!index; }() !! $!index - 1;
            my @g-style := $g.style;

            for @g-style -> $style {
                @!style.push(ScopeStyle.new(
                    beg => last-style.end + $style.beg + 1, style => $style.style.clone()
                ));
                @!style[* - 1].end = $style.end + last-style.end + 1 if $style.end.defined;
            }
        }
        if $replace-style {
            if $g.style.[* - 1].beg > $!index {
                X::Kinoko::Error.new(msg => 'The style-end is bigger than current index.').throw();
            }
            @!style = $g.style.clone();
        }
        self.join($g.data);
    }

    method generator(@max-widths = []) {
        my @style = @!style.clone();

        @style[* - 1].end = self!__last_row_not_empty() ?? $!index !! $!index - 1;

        return my class :: {
            has @.sc;
            has @.content;
            has @.frame;
            has @.v-frame-visibility;
            has @.h-frame-visibility;
            has @.style;
            has @.iterator;
            has @.h-align;
            has @.max-heights;
            has $.index = 0;

            method new(@sc, @style) {
                self.bless(:@sc, :@style);
            }

            method !__gen_max_widths(@max-widths) {
                @!h-align = 0 xx [ .elems for @!sc ].max;
                for @!sc -> \ref {
                    # calc max width of per-col in simple way
                    for ^ref.elems -> $i {
                        if @max-widths[$i].defined && @max-widths[$i] != -1 {
                            @!h-align[$i] = @max-widths[$i];
                        } else {
                            @!h-align[$i] = ref[$i].max-width if ref[$i].max-width > @!h-align[$i];
                        }
                    }
                }
                my Int $align = 0;
                for @!style -> $style {
                    $align = $style.style.content.padding-width
                        if $align < $style.style.content.padding-width;
                }
                @!h-align = @!h-align.map: { $_ + $align };
            }

            method !__align_content() {
                for @!style -> $style {
                    for $style.beg .. $style.end -> $index {
                        # align content and store it into @!content
                        for @(@!sc[$index]) Z, @!h-align -> ($content, $width) {
                            @!content[$index].push(
                                $content
                                .align($width - $style.style.content.padding-width, $style.style.content)
                                .padding($style.style.content)
                            );
                        }
                    }
                }
            }

            method !__gen_max_heights() {
                @!max-heights = [];
                for @!content {
                    # calc max height of per-line in simple way
                    @!max-heights.push(max([ .height for @$_ ]));
                }
            }

            method !__extend_v_content() {
                for @!content Z, @!max-heights <-> ($cref, $h) {
                    for @$cref <-> $c {
                        $c = $c.extend-v($h) if $c.height < $h;
                    }
                }
            }

            method !__gen_frame() {
                for @!style -> $style {
                    my \sref = $style.style;
                    next if sref.line.is-none();
                    for $style.beg .. $style.end -> $index {
                        self!__gen_iterator();
                        my \cref = @(@!content[$index]);
                        my \href = @!max-heights[$index];
                        for ^+cref -> $col {
                            self!__add_cell(
                                href,
                                @!h-align[$col],
                                sref,
                                $index == 0 ??
                                    sref.line.top !!
                                    sref.line.h-middle,
                                ($index == 0 || $col >= @!content[$index - 1].elems) ??
                                    sref.corner.top.middle !!
                                    sref.corner.middle.middle
                            );
                        }
                        my $last-more-than-current = $index <= 0 ?? -1 !!
                            @!content[$index - 1].elems - cref.elems;
                        self!__end_line(href,  @!h-align[cref.elems .. *], sref, $index, $last-more-than-current);
                        self!__incrment_index();
                    }
                }
                unless @!style[* - 1].style.line.is-none() {
                    self!__insert_last_line(@!h-align, @!style[* - 1].style, +@!content[* - 1]);
                }
            }

            method !__gen_iterator() {
                @!frame[$!index] = Array.new;
                @!frame[$!index + 1] = Array.new;
                @!iterator[0] := @!frame[$!index];
                @!iterator[1] := @!frame[$!index + 1];
            }

            method !__add_cell($h, $w, Style $style, $up, $corner) {
                @!iterator[1].push($style.line.v-middle.extend-to($h, :v));
                @!iterator[0].push($up.extend-to($w));
                @!iterator[0].push($corner.clone());
            }

            method !__incrment_index() {
                $!index += 2;
            }

            method !__end_line($h, @w, Style $style, $index, $count) {
                @!iterator[0].unshift(
                    $index == 0 ?? $style.corner.top.left.clone() !!
                        $style.corner.middle.left.clone()
                );
                @!iterator[1].unshift($style.line.left.extend-to($h, :v));
                if $count > -1 {
                    @!iterator[0][* - 1] = $style.corner.middle.middle.clone()
                        if $count > 0;
                    for ^$count {
                        @!iterator[0].append(
                            $style.line.h-middle.extend-to(@w[$_]),
                            $style.corner.bottom.middle.clone()
                        );
                    }
                    if $count == 0 {
                        @!iterator[0][* - 1] = $style.corner.middle.right.clone();
                    } else {
                        @!iterator[0][* - 1] = $style.corner.bottom.right.clone();
                    }
                } else {
                    @!iterator[0][* - 1] = $style.corner.top.right.clone();
                }
                @!iterator[1][* - 1] = $style.line.right.extend-to($h, :v);
            }

            method !__insert_last_line(@w, Style $style, $count) {
                my $last-index = $!index;
                @!frame[$last-index] = Array.new;
                @!frame[$last-index].push($style.corner.bottom.left.clone());
                for ^$count {
                    @!frame[$last-index].append(
                        $style.line.bottom.extend-to(@w[$_]),
                        $style.corner.bottom.middle.clone()
                    );
                }
                @!frame[$last-index][* - 1] = $style.corner.bottom.right.clone();
            }

            method !__gen_frame_visibility() {
                # the frame-visibility about result table
                @!v-frame-visibility = True xx (max(@!content>>.elems) * 2 + 1);
                @!h-frame-visibility = True xx (+@!content * 2 + 1);
            }

            method !__reset() {
                if $!index > 0 {
                    @!content = [];
                    @!frame = [];
                    @!v-frame-visibility = [];
                    @!h-frame-visibility = [];
                    @!iterator = [];
                    @!h-align = [];
                    @!max-heights = [];
                    $!index = 0;
                }
            }

            method generate(@max-widths = []) {
                self!__reset();
                self!__gen_max_widths(@max-widths);
                self!__align_content();
                self!__gen_max_heights();
                self!__extend_v_content();
                self!__gen_frame();
                self!__gen_frame_visibility();
                self;
            }

            method row-count() {
                +@!content;
            }

            method max-count() {
                max(@!content>>.elems);
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

            # for Line Corner
            my multi sub shader-wrapper($f, Bool $color) {
                $f.Str();
            }

            # for Content String
            my multi sub shader-wrapper($pl, String $s, $pr, Bool $color) {
                ?$color && $s.colored() ?? (
                    $pl ~ Shader.colour($s.Str(), $s.style()) ~ $pr
                ) !! ($pl ~ $s.Str() ~ $pr)
            }

            method to-array(Bool :$color = False, :&wrapper = &shader-wrapper) {
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
                my &h-frame = -> @h-frame, @v-frame-visibility {
                    my @t = Array.new;
                    for @h-frame Z, @v-frame-visibility -> ($f, $fv) {
                        @t.push(&shader-wrapper($f, $color)) if $fv;
                    }
                    @table.push(@t);
                };
                my &only-content = -> @content, @v-frame-visibility, $inner_row {
                    my @t = Array.new;
                    for @content -> $c {
                        # C<$inner_row> is current line index
                        @t.push(&shader-wrapper(|$c.get-line($inner_row), $color));
                    }
                    @table.push(@t);
                };
                my &content = -> @v-frame, @v-frame-visibility, @content, $inner_row {
                    my @t = Array.new;
                    for (@v-frame Z, @content).flat Z, @v-frame-visibility -> ($f-or-c, $fv) {
                        @t.push(&shader-wrapper(|$f-or-c.get-line($inner_row), $color)) if $fv;
                    }
                    @t.push(&shader-wrapper(|@v-frame[* - 1].get-line($inner_row), $color))
                        if @v-frame-visibility[* - 1];
                    @table.push(@t);
                };

                self.visit(:&only-content, :&content, :&h-frame);

                return @table;
            }

            method print(Bool :$color = False, :&wrapper = &shader-wrapper) {
                my &h-frame = -> @h-frame, @v-frame-visibility {
                    for @h-frame Z, @v-frame-visibility -> ($f, $fv) {
                        print &shader-wrapper($f, $color) if $fv;
                    }
                    say "";
                };
                my &only-content = -> @content, @v-frame-visibility, $inner_row {
                    for @content -> $c {
                        print &shader-wrapper(|$c.get-line($inner_row), $color);
                    }
                    "".say;
                };
                my &content = -> @v-frame, @v-frame-visibility, @content, $inner_row {
                    for (@v-frame Z, @content).flat Z, @v-frame-visibility -> ($f-or-c, $fv) {
                        print &shader-wrapper(|$f-or-c.get-line($inner_row), $color) if $fv;
                    }
                    print &shader-wrapper(|@v-frame[* - 1].get-line($inner_row), $color)
                        if @v-frame-visibility[* - 1];
                    "".say;
                };

                self.visit(:&only-content, :&content, :&h-frame);
            }

            method visit(:&only-content, :&content, :&h-frame) {
                for @!style -> $style {
                    for $style.beg .. $style.end -> $index {
                        if $style.style.line.is-none() {
                            for ^@(@!content[$index])[0].height -> $r {
                                &only-content(@!content[$index], @!v-frame-visibility, $r)
                                    if ?&only-content;
                            }
                        } else {
                            my $findex = $index * 2;
                            if @!h-frame-visibility[$findex] #`(first frame line) {
                                &h-frame(@!frame[$findex], @!v-frame-visibility)
                                    if ?&h-frame;
                            }
                            for ^@(@!content[$index])[0].height -> $r {
                                if @!h-frame-visibility[$findex + 1] {
                                    # visit second line and second frame line
                                    &content(@!frame[$findex + 1], @!v-frame-visibility, @!content[$index], $r)
                                        if ?&content;
                                }
                            }
                        }
                    }
                }
                unless @!style[* - 1].style.line.is-none() {
                    if @!h-frame-visibility[* - 1] {
                        &h-frame(@!frame[* - 1], @!v-frame-visibility) if &h-frame; # visit last frame line
                    }
                }
            }
        }.new(@!data.clone(), @style).generate(@max-widths);
    }

    method perl() {
        self.defined ?? "Generator.new(style => {@!style[0].style.pelr})" !! "(Generator)";
    }
}
