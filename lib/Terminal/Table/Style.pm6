
use v6;
use Terminal::Table::Frame;
use Terminal::Table::String;
use Terminal::Table::Settings;

enum Style::Default <<
	:NONE('none')
	:ASCII('ascii')
	:SPACE('space')
	:DOT('dot')
	:SINGLE('single')
	:DOUBLE('double')
	:ROUND('round')
>>;

class Style::Corner {
	has @.style handles < AT-POS >;
	has $.mode;

	sub make-corner-array(@array2d) {
		my @ret = Array.new;
		for @array2d -> $inner {
			my @t;
			@t.push(Corner.new(base => String.new(value => $_))) for @$inner;
			@ret.push(@t);
		}
		return @ret;
	}

	submethod TWEAK(:@style, :$mode) {
		@!style = make-corner-array(@style);
		$!mode  = $mode;
	}

	#`(
		pass :count to get style number, the style index base on zero.
	)
	method none(Int $index = 0, :$count) {
		return 1 if ?$count;
		return self.new(
			style => [
				['',  '', ''],
				['',  '', ''],
				['',  '', ''],
			],
			mode => NONE
		);
	}

	method space(Int $index = 0, :$count) {
		return 1 if ?$count;
		return self.new(
			style => [
                [' ',  ' ', ' '],
                [' ',  ' ', ' '],
                [' ',  ' ', ' '],
            ],
			mode => SPACE
		);
	}

	method ascii(Int $index = 0, :$count) {
		return 1 if ?$count;
		return self.new(
			style => [
				['+',  '+', '+'],
				['+',  '+', '+'],
				['+',  '+', '+'],
			],
			mode => ASCII
		);
	}

	method single(Int $index = 0, :$count) {
		return 4 if ?$count;
		given $index {
			when 0 {
				return self.new(
					style => [
						<┌ ┬ ┐>,
						<├ ┼ ┤>,
						<└ ┴ ┘>,
					],
					mode => SINGLE
				);
			}
			when 1 {
				return self.new(
					style => [
		                <┏ ┳ ┓>,
		                <┣ ╋ ┫>,
		                <┗ ┻ ┛>,
		            ],
					mode => SINGLE
				);
			}
			when 2 {
				return self.new(
					style => [
		                <┍ ┰ ┑>,
		                <┝ ┿ ┥>,
		                <┕ ┸ ┙>,
		            ],
					mode => SINGLE
				);
			}
			when 3 {
				return self.new(
					style => [
		                <┎ ┯ ┒>,
		                <┠ ╂ ┨>,
		                <┖ ┷ ┚>,
		            ],
					mode => SINGLE
				);
			}
		}
	}

	method double(Int $index = 0, :$count) {
		return 3 if ?$count;
		given $index {
			when 0 {
				return self.new(
					style => [
		                <╔ ╦ ╗>,
		                <╠ ╬ ╣>,
		                <╚ ╩ ╝>,
		            ],
					mode => DOUBLE
				);
			}
			when 1 {
				return self.new(
					style => [
		                <╒ ╤ ╕>,
		                <╞ ╪ ╡>,
		                <╘ ╧ ╛>,
		            ],
					mode => DOUBLE
				);
			}
			when 2 {
				return self.new(
					style => [
		                <╓ ╥ ╖>,
		                <╟ ╫ ╢>,
		                <╙ ╨ ╜>,
		            ],
					mode => DOUBLE
				);
			}
		}
	}

	method round(Int $index = 0, :$count) {
		return 2 if ?$count;
		given $index {
			when 1 {
				return self.new(
					style => [
						<╭ ╦ ╮>,
						<╠ ╬ ╣>,
						<╰ ╩ ╯>,
					],
					mode => ROUND
				);
			}
			when 0 {
				return self.new(
					style => [
						<╭ ┬ ╮>,
						<├ ┼ ┤>,
						<╰ ┴ ╯>,
					],
					mode => ROUND
				);
			}
		}
	}

	my enum Pos  <<  :Top(0) :Bottom(2) :Left(0) :Middle(1) :Right(2) >>;

	my class StyleLine {
		has $.ref-style;

		method new(\ref) {
			self.bless()!init(ref);
		}

		method !init(\ref) {
			$!ref-style := ref;
			self;
		}

		method left {
			$!ref-style[Pos::Left];
		}

		method middle {
			$!ref-style[Pos::Middle];
		}

		method right {
			$!ref-style[Pos::Right];
		}
	}

	method top {
		my \ref = @!style[Pos::Top];
		StyleLine.new(ref);
	}

	method middle {
		my \ref = @!style[Pos::Middle];
		StyleLine.new(ref);
	}

	method bottom {
		my \ref = @!style[Pos::Bottom];
		StyleLine.new(ref);
	}

	method is-none() {
		$!mode eq NONE;
	}
}

class Style::Line {
	has Line $.top;
	has Line $.h-middle;
	has Line $.bottom;
	has Line $.left;
	has Line $.v-middle;
	has Line $.right;
	has      $.mode;

	sub make-line(Str $str, $width) is export {
	    return Line.new(base => String.new(value => $str, :$width));
	}

	method new(:$mode, *%args) {
		my @strs = [];
		for %args.keys() -> $key {
			@strs.push(make-line(|%args{$key}));
		}
		self.bless(|%(
				%args.keys() Z=> @strs
			),
			:$mode
		);
	}

	method none(Int $index = 0, :$count) {
		return 1 if ?$count;
		return self.new(
			top 		=> ['', 0],
			h-middle 	=> ['', 0],
			bottom 		=> ['', 0],
			left 		=> ['', 0],
			v-middle 	=> ['', 0],
			right 		=> ['', 0],
			mode 		=> NONE
		);
	}

	method ascii(Int $index = 0, :$count) {
		return 1 if ?$count;
		return self.new(
			top 		=> ['-', 1],
			h-middle 	=> ['-', 1],
			bottom 		=> ['-', 1],
			left 		=> ['|', 1],
			v-middle 	=> ['|', 1],
			right 		=> ['|', 1],
			mode 		=> ASCII
		)
	}

	method space(Int $index = 0, :$count) {
		return 1 if ?$count;
		return self.new(
			top 		=> [' ', 1],
			h-middle 	=> [' ', 1],
			bottom 		=> [' ', 1],
			left 		=> [' ', 1],
			v-middle 	=> [' ', 1],
			right 		=> [' ', 1],
			mode 		=> SPACE
		)
	}

	multi method single(Int $index = 0, :$count) {
		return 4 if ?$count;
		given $index {
			when 0 {
				return self.new(
					top 		=> ['─', 1],
					h-middle 	=> ['─', 1],
					bottom 		=> ['─', 1],
					left 		=> ['│', 1],
					v-middle 	=> ['│', 1],
					right 		=> ['│', 1],
					mode 		=> SINGLE
				);
			}
			when 1 {
				return self.new(
					top 		=> ['━', 1],
					h-middle 	=> ['━', 1],
					bottom 		=> ['━', 1],
					left 		=> ['┃', 1],
					v-middle 	=> ['┃', 1],
					right 		=> ['┃', 1],
					mode 		=> SINGLE
				);
			}
			when 2 {
				return self.new(
					top 		=> ['╼', 1],
					h-middle 	=> ['╼', 1],
					bottom 		=> ['╼', 1],
					left 		=> ['╽', 1],
					v-middle 	=> ['╽', 1],
					right 		=> ['╽', 1],
					mode 		=> SINGLE
				);
			}
			when 3 {
				return self.new(
					top 		=> ['╾', 1],
					h-middle 	=> ['╾', 1],
					bottom 		=> ['╾', 1],
					left 		=> ['╿', 1],
					v-middle 	=> ['╿', 1],
					right 		=> ['╿', 1],
					mode 		=> SINGLE
				);
			}
		}
	}

	method double(Int $index = 0, :$count) {
		return 1 if ?$count;
		return self.new(
			top 		=> ['═', 1],
			h-middle 	=> ['═', 1],
			bottom 		=> ['═', 1],
			left 		=> ['║', 1],
			v-middle 	=> ['║', 1],
			right 		=> ['║', 1],
			mode 		=> DOUBLE
		)
	}

	method dot(Int $index = 0, :$count) {
		return 6 if ?$count;
		given $index {
			when 0 {
				return self.new(
					top 		=> ['╌', 1],
					h-middle 	=> ['╌', 1],
					bottom 		=> ['╌', 1],
					left 		=> ['╎', 1],
					v-middle 	=> ['╎', 1],
					right 		=> ['╎', 1],
					mode 		=> DOT
				)
			}
			when 1 {
				return self.new(
					top 		=> ['╍', 1],
					h-middle 	=> ['╍', 1],
					bottom 		=> ['╍', 1],
					left 		=> ['╏', 1],
					v-middle 	=> ['╏', 1],
					right 		=> ['╏', 1],
					mode 		=> DOT
				)
			}
			when 2 {
				return self.new(
					top 		=> ['┅', 1],
					h-middle 	=> ['┅', 1],
					bottom 		=> ['┅', 1],
					left 		=> ['┇', 1],
					v-middle 	=> ['┇', 1],
					right 		=> ['┇', 1],
					mode 		=> DOT
				);
			}
			when 3 {
				return self.new(
					top 		=> ['┄', 1],
					h-middle 	=> ['┄', 1],
					bottom 		=> ['┄', 1],
					left 		=> ['┆', 1],
					v-middle 	=> ['┆', 1],
					right 		=> ['┆', 1],
					mode 		=> DOT
				);
			}
			when 4 {
				return self.new(
					top 		=> ['┈', 1],
					h-middle 	=> ['┈', 1],
					bottom 		=> ['┈', 1],
					left 		=> ['┊', 1],
					v-middle 	=> ['┊', 1],
					right 		=> ['┊', 1],
					mode 		=> DOT
				);
			}
			when 5 {
				return self.new(
					top 		=> ['┉', 1],
					h-middle 	=> ['┉', 1],
					bottom 		=> ['┉', 1],
					left 		=> ['┋', 1],
					v-middle 	=> ['┋', 1],
					right 		=> ['┋', 1],
					mode 		=> DOT
				);
			}
		}
	}

	method is-none() {
		$!mode eq NONE;
	}
}

enum Align <<
	:LEFT(0)
	:RIGHT(1)
	:MIDDLE(2)
>>;

class Style::Content {
	has String $.padding-char = String.new(value => " ", width => 1);
	has Int 	$.padding-left  = 0;
	has Int 	$.padding-right = 0;
	has 		$.align         = Align::LEFT;
	has Bool    $.split-word    = False;

	method space() {
		self.new(:padding-char(String.new(value => " ", width => 1)));
	}

	method align-left() {
		$!align == Align::LEFT;
	}

	method align-right() {
		$!align == Align::RIGHT;
	}

	method align-middle() {
		$!align == Align::MIDDLE;
	}

	method padding-width() {
		($!padding-left + $!padding-right) * $!padding-char.width;
	}
}


class Style {
	has Style::Corner	$.corner-style;
	has Style::Line		$.line-style;
	has Style::Content	$.content-style;

	submethod TWEAK(*%args) {
		if %args<corner-style>.is-none() {
			unless %args<line-style>.is-none() {
				X::Kinoko::Error.new(msg => 'none style expect!').throw();
			}
		}
	}

	method corner {
		$!corner-style;
	}

	method line {
		$!line-style;
	}

	method content {
		$!content-style;
	}
}

class Color::String {
	# style for Terminal::ANSIColor
	has @.color;
	has $.enabled = True;

	method color-style() {
		@!color.join(" ");
	}

	method append(@color) {
		@!color.append(@color);
	}

	method enable() {
		$!enabled = True;
	}

	method disable() {
		$!enabled = False;
	}
}
