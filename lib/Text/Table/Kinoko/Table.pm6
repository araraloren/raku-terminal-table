
use v6;
use Text::Table::Kinoko::Char;
use Text::Table::Kinoko::Styler;
use Text::Table::Kinoko::Frame;
use Text::Table::Kinoko::Array2D;
use Text::Table::Kinoko::Content;
use Text::Table::Kinoko::Exception;

class Table {
    has $.data;
    has $.styler;
    has $!complete = False;
    has $!index = 0;

    method new(Styler :$styler, :$data = Array2D.new) {
        self.bless( :$styler, :$data);
    }

    method !__check_complete() {
        unless $!complete {
            X::Kinoko::Error.new("Table can not access before commit.").throw();
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
        $!data[$!index + 1].push($str);
        $!data[$!index + 1].push($!styler.line.right);
        $!data[$!index].push($!styler.line.top);
        if $!index == 0 || $!data[$!index + 1].elems > $!data[$!index - 1].elems {
            $!data[$!index].push($!styler.corner[Styler::Pos::Top][Styler::Pos::Middle]);
        } else {
            $!data[$!index].push($!styler.corner[Styler::Pos::Middle][Styler::Pos::Middle]);
        }
    }

    # end line
    # last top middle corner => top right
    # add top left corner
    # add left line
    method end-line() {
        if $!index == 0 {
            $!data[$!index][$!data[$!index].elems - 1] = $!styler.corner[Styler::Pos::Top][Styler::Pos::Right];
            $!data[$!index].unshift($!styler.corner[Styler::Pos::Top][Styler::Pos::Left]);
        } else {
            if $!data[$!index + 1].elems > $!data[$!index - 1].elems {
                $!data[$!index][$!data[$!index].elems - 1] = $!styler.corner[Styler::Pos::Top][Styler::Pos::Right];
            } else {
                $!data[$!index][$!data[$!index].elems - 1] = $!styler.corner[Styler::Pos::Middle][Styler::Pos::Right];
            }
            $!data[$!index].unshift($!styler.corner[Styler::Pos::Middle][Styler::Pos::Left]);
        }
        $!data[$!index + 1].unshift($!styler.line.left);
        $!index += 2;
    }

    method join() {
        
    }

    method cell(Int $x, Int $y) {
        self!__check_complete();
        return class :: {
            has $.top;
            has $.lower;
            has $.left;
            has $.right;
            has $.content;
        }.new();
    }
}
