
use v6;
use Text::Table::Kinoko::Char;
use Text::Table::Kinoko::Style;
use Text::Table::Kinoko::Frame;
use Text::Table::Kinoko::Array2D;
use Text::Table::Kinoko::Content;
use Text::Table::Kinoko::Exception;

class Generator {
    has $.data;
    has $.style;
    has $!committed = False;
    has $.index = 0;

    method new(Style :$style is copy, :$data = Array2D.new) {
        self.bless( :$style, :$data);
    }

    method __expect_committed() {
        unless $!committed {
            X::Kinoko::Error.new("Table can not join able before commit.").throw();
        }
    }

    sub printArray(Array2D $arr) {
        for 0 ..^ $arr.elems -> $x {
            my \a1d = $arr[$x];
            for 0 ..^ a1d.elems -> $y {
                print a1d[$y], " ";
            }
            print "\n";
        }
    }

    method print() {
        printArray($!data) if ?$!data;
    }

    # add top - corner
    #   content   |<right>
    method add-cell(Char $str) {
        $!data[$!index + 1].push(Content.new(str => $str));
        $!data[$!index + 1].push($!style.line.right);
        $!data[$!index].push($!style.line.top);
        if $!index == 0 || $!data[$!index + 1].elems > $!data[$!index - 1].elems {
            $!data[$!index].push($!style.corner.top.middle);
        } else {
            $!data[$!index].push($!style.corner.middle.middle);
        }
    }

    # end line
    # last top middle corner => top right
    # add top left corner
    # add left line
    method end-line() {
        # process current line
        if $!index == 0 {
            $!data[$!index][* - 1] = $!style.corner.top.right;
            $!data[$!index].unshift($!style.corner.top.left);
        } else {
            if $!data[$!index + 1].elems > $!data[$!index - 1].elems {
                $!data[$!index][* - 1] = $!style.corner.top.right;
            } else {
                $!data[$!index][* - 1] = $!style.corner.middle.right;
            }
            $!data[$!index].unshift($!style.corner.middle.left);
        }
        $!data[$!index + 1].unshift($!style.line.left);
        # process last-line
        if $!index > 1 && $!data[$!index].elems < $!data[$!index - 1].elems {
            $!data[$!index][* - 1] = $!style.corner.middle.middle;
            loop (my $i = $!data[$!index].elems;$i < $!data[$!index - 1].elems;$i += 2) {
                $!data[$!index][$i] = $!style.line.bottom;
                $!data[$!index][$i + 1]  = $!style.corner.bottom.middle;
            }
            $!data[$!index][$!data[$!index - 1].elems - 1] = $!style.corner.bottom.right;
        }
        $!index += 2;
    }

    method commit() {
        $!data[$!index].push($!style.corner.bottom.left);
        for 1 .. (($!data[$!index - 1].elems - 1) div 2) {
            $!data[$!index].push($!style.line.bottom);
            $!data[$!index].push($!style.corner.bottom.middle);
        }
        $!data[$!index][$!data[$!index].elems - 1] = $!style.corner.bottom.right;
        $!committed = True;
    }

    # join left
    # self
    # $t
    method join(Generator $t, :$down, :$preserve-style) {
        self.__expect_committed();
        $t.__expect_committed();
        for 1 .. $t.index {
            $!data[$!index + $_].append($t.data[$_])
        }
        if ?$preserve-style {
            $!data[$!index][0] = $!style.corner.middle.left;
            loop (my $i = 2;$i < $!data[$!index + 1].elems;$i += 2) {
                $!data[$!index][$i] = $!style.corner.middle.middle;
            }
            if $!data[$!index].elems > $!data[$!index + 1].elems {
                $!data[$!index][$!data[$!index + 1].elems - 1]  = $!style.corner.middle.middle;
            } else {
                $!data[$!index][$!data[$!index + 1].elems - 1]  = $!style.corner.top.right;
            }
        } else {
            $!data[$!index][$_] = $t.data[0][$_] for ^$!data[$!index + 1].elems;
            $!data[$!index][0] = $t.style.corner.middle.left;
            loop (my $i = 2;$i < $!data[$!index + 1].elems;$i += 2) {
                $!data[$!index][$i] = $t.style.corner.middle.middle;
            }
            if $!data[$!index].elems > $!data[$!index + 1].elems {
                $!data[$!index][$!data[$!index + 1].elems - 1]  = $t.style.corner.middle.middle;
            } else {
                $!data[$!index][$!data[$!index + 1].elems - 1]  = $t.style.corner.top.right;
            }
        }
        $!index += $t.index;
    }

    method gen-table() {
        my @table = to-array($!data);

        my @max-widths = [ 0 xx [ @table[$_].elems for 1, 3 ... $!index ].max ];

        for 1, 3 ...^ $!index {
            my \ref = @table[$_];

            # get max width of per-col in simple way
            for ^ref.elems -> $i {
                @max-widths[$i] = ref[$i].width if ref[$i].width > @max-widths[$i];
            }
        }
        for 1, 3 ... $!index -> $r {
            my \pre = @table[$r - 1];
            my \ref = @table[$r];

            for 1, 3 ...^ ref.elems -> $c {
                pre[$c].extend(@max-widths[$c] + $!style.content.indent);
                ref[$c].align(@max-widths[$c], $!style.content);
            }
        }
        @table;
    }

    method is-empty() {
        $!data.elems == 0;
    }
}
