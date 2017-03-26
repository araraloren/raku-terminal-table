
use v6;

enum Styler::Mode < NONE M_SPACE M_DEFAULT M_DOUBLE M_ROUNDED >

enum Styler::Align < MIDDLE LEFT RIGHT >

constant SC_TOP     is export = 0;
constant SC_LOWER   is export = 2;
constant SC_LEFT    is export = 0;
constant SC_MIDDLE  is export = 1;
constant SC_RIGHT   is export = 2;

class Styler::Corner {
    has @.style;
    has @.width;

    method none () {}

    method space () {
        self.new (
            style => (
                [" ", " ", " "],
                [" ", " ", " "],
                [" ", " ", " "],
            ),
            width => (
                [1, 1, 1],
                [1, 1, 1],
                [1, 1, 1],
            )
        );
    }

    method default () {
        self.new (
            style => (
                <┌ ┬ ┐>,
                <├ ┼ ┤>,
                <└ ┴ ┘>,
            ),
            width => (
                [1, 1, 1],
                [1, 1, 1],
                [1, 1, 1],
            )
        );
    }

    multi method style(Int $x) {
        return @!style[$x];
    }

    multi method style(Int $x, Int $y) {
        return @!style[$x][$y];
    }

    multi method width(Int $x) {
        return @!width[$x];
    }

    multi method width(Int $x, Int $y) {
        return @!width[$x][$y];
    }
}

class Styler::Table {
    has Corner @.corner;
    has Brick $.top;
    has Brick $.horizontal-middle;
    has Brick $.lower;
    has Brick $.left;
    has Brick $.right;
    has Brick $.vertical-middle;

    method none () { }

    method space () {
        self.new (
            corner              => Styler::Corner.space(),
            top                 => Brick.new(" ", 1),
            horizontal-middle   => Brick.new(" ", 1),
            lower               => Brick.new(" ", 1),
            left                => Brick.new(" ", 1),
            right               => Brick.new(" ", 1),
            vertical-middle     => Brick.new(" ", 1),
        );
    }

    method default () {
        self.new (
            corner              => Styler::Corner.none(),
            top                 => Brick.new("─", 1),
            horizontal-middle   => Brick.new("─", 1),
            lower               => Brick.new("─", 1),
            left                => Brick.new("│", 1),
            right               => Brick.new("│", 1),
            vertical-middle     => Brick.new("│", 1),
        );
    }

    method new (:$corner, *%args) {
        my Corner @corner;

        for ^3 {
            @corner.push([ Corner.new($^s, $^w) for ($corner.style($_), $corner.width($_)) ]);
        }
        self.bless(corner => @corner, |%args);
    }
}