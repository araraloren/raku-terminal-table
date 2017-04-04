
use v6;
use Text::Table::Kinoko::KString;
use Text::Table::Kinoko::Style;
use Text::Table::Kinoko::Frame;
use Text::Table::Kinoko::Array2D;
use Text::Table::Kinoko::Content;
use Text::Table::Kinoko::DeepClone;
use Text::Table::Kinoko::Exception;

class Generator {
    my class ScopeStyle {
        has Int $.beg is rw;
        has Int $.end is rw;
        has     $.style;
    }

    has @.data handles <AT-POS ASSIGN-POS iterator list>;
    has @.style;
    has $!index = 0;

    method new(Style :$style is copy) {
        self.bless(style => [ ScopeStyle.new(beg => 0, style => $style), ]);
    }

    multi method add-cell($s where * !~~ Str | KString) {
        @!data[$!index].push(Content.new(str => $s.Str));
    }

    multi method add-cell($str where * ~~ Str | KString) {
        @!data[$!index].push(Content.new(str => $str));
    }

    method end-line() {
        $!index++;
    }

    method !__last_row_not_empty() {
        @!data[$!index].defined && @!data[$!index].elems > 0;
    }

    multi method join(@array) {
        self.end-line() if self!__last_row_not_empty();

        for @array -> $inner-array {
            if $inner-array.elems > 0 {
                @!data[$!index].push(Content.new(str => .Str)) for @$inner-array;
                self.end-line();
            }
        }
    }

    multi method join(Generator $g, :$preserve-style) {
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
        self.join($g.data);
    }

    method gen-table() {
        my @style = @!style.clone();

        @style[* - 1].end = self!__last_row_not_empty() ?? $!index !! $!index - 1;

        my \ref := @!data;
        return my class :: {
            has @.content;
            has @.max-widths;
            has @.data;
            has @.style;
            has @.style-caches;
            has $.index = 0;
            has @.iterator;

            method new(\content, @style) {
                self.bless(:@style)!__init(content)!__gen_table();
            }

            method !__init(\content) {
                self!__gen_max_widths(content);
                self!__gen_content_and_style(content);
                self;
            }

            method !__gen_max_widths(\content) {
                @!max-widths = 0 xx [ .elems for @(content) ].max;
                for @(content) -> \ref {
                    # calc max width of per-col in simple way
                    for ^ref.elems -> $i {
                        @!max-widths[$i] = ref[$i].width if ref[$i].width > @!max-widths[$i];
                    }
                }
            }

            method !__gen_content_and_style(\content) {
                for @!style -> $style {
                    for $style.beg .. $style.end -> $index {
                        # align content and store it into @!content
                        for @(content.[$index]) Z, @!max-widths -> ($content, $width) {
                            @!content[$index].push($content.align($width, $style.style.content));
                        }
                    }
                    # make style cache for per-col
                    my @realw = [ $_ + $style.style.content.indent for @!max-widths ];
                    @!style-caches.push(%(
                        top => [$style.style.line.top.extend($_) for @realw],
                        middle => [$style.style.line.h-middle.extend($_) for @realw],
                        # bottom only used when last line insert
                        bottom => [$style.style.line.bottom.extend($_) for @realw],
                        # use default left and right、v-middle
                    ));
                }
            }

            method !__gen_table() {
                for ^+@!style -> $i {
                    my $style := @!style[$i];
                    for $style.beg .. $style.end -> $index {
                        self!__gen_iterator();
                        for ^+@(@!content[$index]) -> $col  {
                            my $cache := @(@!style-caches[$i]{ $i == 0 ?? 'top' !! 'middle' })[$col];
                            # get cache for current column
                            self!__add_cell(@(@!content[$index])[$col], $style.style, $cache);
                        }
                        self!__end_line($style.style, @(@!style-caches[$i]<bottom>));
                        self!__incrment_index();
                    }
                }
                self!__insert_last_line(@!style[* - 1].style, @(@!style-caches[* - 1]<bottom>));
                self;
            }

            method !__gen_iterator() {
                @!data[$!index] = Array.new;
                @!data[$!index + 1] = Array.new;
                @!iterator[0] := @!data[$!index];
                @!iterator[1] := @!data[$!index + 1];
            }

            method !__incrment_index() {
                $!index += 2;
            }

            method !__add_cell(Content $c, Style $style, $cache) {
                @!iterator[1].push($c.Str());
                @!iterator[1].push($style.line.v-middle.Str);
                @!iterator[0].push($cache.Str);
                if $!index == 0 || @!data[$!index + 1].elems > @!data[$!index - 1].elems {
                    @!iterator[0].push($style.corner.top.middle.Str);
                } else {
                    @!iterator[0].push($style.corner.middle.middle.Str);
                }
            }

            method !__end_line(Style $style, @bottom-cache) {
                @!iterator[0].unshift($!index == 0 ?? $style.corner.top.left.Str !! $style.corner.middle.left.Str);
                @!iterator[1].unshift($style.line.left.Str);
                if $!index > 1 && @!iterator[0].elems <= @!data[$!index - 1].elems {
                    @!iterator[0][* - 1] = $style.corner.middle.middle.Str;
                    loop (my $i = @!iterator[0].elems;$i < @!data[$!index - 1].elems;$i += 2) {
                        @!iterator[0].append(@bottom-cache[$i div 2].Str, $style.corner.bottom.middle.Str);
                    }
                    # must use
                    if @!iterator[1].elems == @!data[$!index - 1].elems {
                        @!iterator[0][* - 1] =  $style.corner.middle.right.Str;
                    } else {
                        @!iterator[0][* - 1] =  $style.corner.bottom.right.Str;
                    }
                } else {
                    # process { top left corner | left line } when last line insert
                    @!iterator[0][* - 1] = $style.corner.top.right.Str;
                }
                @!iterator[1][* - 1] = $style.line.right.Str;
            }

            method !__insert_last_line(Style $style, @bottom-cache) {
                my $last-index = $!index;
                @!data[$last-index] = Array.new;
                @!data[$last-index].push($style.corner.bottom.left.Str);
                loop (my $i = 1;$i < @!iterator[1].elems;$i += 2) {
                    @!data[$last-index].append(@bottom-cache[$i div 2].Str, $style.corner.bottom.middle.Str);
                }
                @!data[$last-index][* - 1] = $style.corner.bottom.right.Str;
            }

            method print() {
                for @!data {
                    .join("").say;
                }
            }
        }.new(ref, @style);
    }

    method print() {
        for @!data -> $inner {
            say @$inner.join(" ");
        }
    }
}
