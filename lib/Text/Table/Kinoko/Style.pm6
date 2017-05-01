
use v6;
use Text::Table::Kinoko::Frame;
use Text::Table::Kinoko::String;
use Text::Table::Kinoko::Settings;

constant NONE 		= 'none';
constant SPACE 		= ' ';
constant SINGLE 	= '-';
constant DOUBLE 	= '--';

class Style::Corner {
	has @.style handles < AT-POS >;
	has $.mode;

	sub make-corner-array(@array2d) {
		my @ret;

		for @array2d -> $inner {
			my @t;
			@t.push(Corner.new(str => $_)) for @$inner;
			@ret.push(@t);
		}
		return @ret;
	}

	method none() {
		self.new(
			style => make-corner-array([
				['',  '', ''],
				['',  '', ''],
				['',  '', ''],
			]),
			mode => NONE
		);
	}

	method space() {
		self.new(
			style => make-corner-array([
                [' ',  ' ', ' '],
                [' ',  ' ', ' '],
                [' ',  ' ', ' '],
            ]),
			mode => Style::Type::Space
		);
	}

	method single(:$bold, :$bold1, :$bold2) {
		if ?$bold {
			return self.new(
				style => make-corner-array([
	                <┏ ┳ ┓>,
	                <┣ ╋ ┫>,
	                <┗ ┻ ┛>,
	            ]),
				mode => SINGLE
			);
		}
		if ?$bold1 {
			return self.new(
				style => make-corner-array([
	                <┍ ┰ ┑>,
	                <┝ ┿ ┥>,
	                <┕ ┸ ┙>,
	            ]),
				mode => SINGLE
			);
		}
		if ?$bold2 {
			return self.new(
				style => make-corner-array([
	                <┎ ┯ ┒>,
	                <┠ ╂ ┨>,
	                <┖ ┷ ┚>,
	            ]),
				mode => SINGLE
			);
		}
		return self.new(
			style => make-corner-array([
				<┌ ┬ ┐>,
				<├ ┼ ┤>,
				<└ ┴ ┘>,
			]),
			mode => SINGLE
		);
	}

	method double(:$single, :$single1) {
		if ?$single {
			return self.new(
				style => make-corner-array([
	                <╒ ╤ ╕>,
	                <╞ ╪ ╡>,
	                <╘ ╧ ╛>,
	            ]),
				mode => DOUBLE
			);
		}
		if ?$single1 {
			return self.new(
				style => make-corner-array([
	                <╓ ╥ ╖>,
	                <╟ ╫ ╢>,
	                <╙ ╨ ╜>,
	            ]),
				mode => DOUBLE
			);
		}
		return self.new(
			style => make-corner-array([
                <╔ ╦ ╗>,
                <╠ ╬ ╣>,
                <╚ ╩ ╝>,
            ]),
			mode => DOUBLE
		);
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
	    return Line.new(:$str, :$width, n => 1);
	}

	method none() {
		self.new(
			top 		=> make-line('', 0),
			h-middle 	=> make-line('', 0),
			bottom 		=> make-line('', 0),
			left 		=> make-line('', 0),
			v-middle 	=> make-line('', 0),
			right 		=> make-line('', 0),
			mode 		=> NONE
		);
	}

	method space() {
		self.new(
			top 		=> make-line(' ', 1),
			h-middle 	=> make-line(' ', 1),
			bottom 		=> make-line(' ', 1),
			left 		=> make-line(' ', 1),
			v-middle 	=> make-line(' ', 1),
			right 		=> make-line(' ', 1),
			mode 		=> SPACE
		)
	}

	multi method single(:$bold) {
		if ?$bold {
			return self.new(
				top 		=> make-line('━', 1),
				h-middle 	=> make-line('━', 1),
				bottom 		=> make-line('━', 1),
				left 		=> make-line('┃', 1),
				v-middle 	=> make-line('┃', 1),
				right 		=> make-line('┃', 1),
				mode 		=> SINGLE
			);
		}
		return self.new(
			top 		=> make-line('─', 1),
			h-middle 	=> make-line('─', 1),
			bottom 		=> make-line('─', 1),
			left 		=> make-line('│', 1),
			v-middle 	=> make-line('│', 1),
			right 		=> make-line('│', 1),
			mode 		=> SINGLE
		);
	}

	method double() {
		self.new(
			top 		=> make-line('═', 1),
			h-middle 	=> make-line('═', 1),
			bottom 		=> make-line('═', 1),
			left 		=> make-line('║', 1),
			v-middle 	=> make-line('║', 1),
			right 		=> make-line('║', 1),
			mode 		=> DOUBLE
		)
	}

	method dot() {
		self.new(
			top 		=> make-line('╍', 1),
			h-middle 	=> make-line('╍', 1),
			bottom 		=> make-line('╍', 1),
			left 		=> make-line('╏', 1),
			v-middle 	=> make-line('╏', 1),
			right 		=> make-line('╏', 1),
			mode 		=> Style::Type::Double2
		)
	}

	method dot2() {
		self.new(
			top 		=> make-line('╍', 1),
			h-middle 	=> make-line('╍', 1),
			bottom 		=> make-line('╍', 1),
			left 		=> make-line('╏', 1),
			v-middle 	=> make-line('╏', 1),
			right 		=> make-line('╏', 1),
			mode 		=> Style::Type::Double2
		)
	}

	method is-none() {
		$!mode eq NONE;
	}
}

class Style::Content {
	has String $.padding-char;
	has Int 	$.padding-left;
	has Int 	$.padding-right;
	has 		$.align;
	has Bool    $.split-word;

	my enum Align 	<< Left Right Middle >>;

	method new (
		:$padding-char = String.new(str => " ", width => 1),
		:$padding-left = 2,
		:$padding-right = 0,
		:$align = Align::Left,
		:$split-word = False,
	) {
		self.bless(
			:$padding-char, :$padding-left,
			:$padding-right, :$align,
			:$split-word
		);
	}

	method space () {
		self.new();
	}

	method align-left() {
		$!align == Align::Left;
	}

	method align-right() {
		$!align == Align::Right;
	}

	method align-middle() {
		$!align == Align::Middle;
	}

	method padding-width() {
		($!padding-left + $!padding-right) * $!padding-char.width;
	}
}


class Style {
	has Style::Corner	$.corner-style;
	has Style::Line		$.line-style;
	has Style::Content	$.content-style;

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
