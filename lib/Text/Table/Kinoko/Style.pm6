
use v6;
use Text::Table::Kinoko::KString;
use Text::Table::Kinoko::Frame;

constant NONE 		= 'none';
constant SPACE 		= ' ';
constant SINGLE 	= '-';
constant DOUBLE 	= '--';

class Style::Corner {
	has @.style handles < AT-POS >;
	has $.mode;

	method none() {
		self.new(
			#`(style => makeCornerArray2([
				['',  '', ''],
				['',  '', ''],
				['',  '', ''],
			]),)
			mode => NONE
		);
	}

	method space() {
		self.new(
			style => makeCornerArray2([
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
				style => makeCornerArray2([
	                <┏ ┳ ┓>,
	                <┣ ╋ ┫>,
	                <┗ ┻ ┛>,
	            ]),
				mode => SINGLE
			);
		}
		if ?$bold1 {
			return self.new(
				style => makeCornerArray2([
	                <┍ ┰ ┑>,
	                <┝ ┿ ┥>,
	                <┕ ┸ ┙>,
	            ]),
				mode => SINGLE
			);
		}
		if ?$bold2 {
			return self.new(
				style => makeCornerArray2([
	                <┎ ┯ ┒>,
	                <┠ ╂ ┨>,
	                <┖ ┷ ┚>,
	            ]),
				mode => SINGLE
			);
		}
		return self.new(
			style => makeCornerArray2([
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
				style => makeCornerArray2([
	                <╒ ╤ ╕>,
	                <╞ ╪ ╡>,
	                <╘ ╧ ╛>,
	            ]),
				mode => DOUBLE
			);
		}
		if ?$single1 {
			return self.new(
				style => makeCornerArray2([
	                <╓ ╥ ╖>,
	                <╟ ╫ ╢>,
	                <╙ ╨ ╜>,
	            ]),
				mode => DOUBLE
			);
		}
		return self.new(
			style => makeCornerArray2([
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

	method none() {
		self.new(
			top 		=> makeLine('', 0),
			h-middle 	=> makeLine('', 0),
			bottom 		=> makeLine('', 0),
			left 		=> makeLine('', 0),
			v-middle 	=> makeLine('', 0),
			right 		=> makeLine('', 0),
			mode 		=> NONE
		);
	}

	method space() {
		self.new(
			top 		=> makeLine(' ', 1),
			h-middle 	=> makeLine(' ', 1),
			bottom 		=> makeLine(' ', 1),
			left 		=> makeLine(' ', 1),
			v-middle 	=> makeLine(' ', 1),
			right 		=> makeLine(' ', 1),
			mode 		=> SPACE
		)
	}

	multi method single(:$bold) {
		if ?$bold {
			return self.new(
				top 		=> makeLine('━', 1),
				h-middle 	=> makeLine('━', 1),
				bottom 		=> makeLine('━', 1),
				left 		=> makeLine('┃', 1),
				v-middle 	=> makeLine('┃', 1),
				right 		=> makeLine('┃', 1),
				mode 		=> SINGLE
			);
		}
		return self.new(
			top 		=> makeLine('─', 1),
			h-middle 	=> makeLine('─', 1),
			bottom 		=> makeLine('─', 1),
			left 		=> makeLine('│', 1),
			v-middle 	=> makeLine('│', 1),
			right 		=> makeLine('│', 1),
			mode 		=> SINGLE
		);
	}

	method double() {
		self.new(
			top 		=> makeLine('═', 1),
			h-middle 	=> makeLine('═', 1),
			bottom 		=> makeLine('═', 1),
			left 		=> makeLine('║', 1),
			v-middle 	=> makeLine('║', 1),
			right 		=> makeLine('║', 1),
			mode 		=> DOUBLE
		)
	}

	method dot() {
		self.new(
			top 		=> makeLine('╍', 1),
			h-middle 	=> makeLine('╍', 1),
			bottom 		=> makeLine('╍', 1),
			left 		=> makeLine('╏', 1),
			v-middle 	=> makeLine('╏', 1),
			right 		=> makeLine('╏', 1),
			mode 		=> Style::Type::Double2
		)
	}

	method dot2() {
		self.new(
			top 		=> makeLine('╍', 1),
			h-middle 	=> makeLine('╍', 1),
			bottom 		=> makeLine('╍', 1),
			left 		=> makeLine('╏', 1),
			v-middle 	=> makeLine('╏', 1),
			right 		=> makeLine('╏', 1),
			mode 		=> Style::Type::Double2
		)
	}

	method is-none() {
		$!mode eq NONE;
	}
}

class Style::Content {
	has KString $.padding-char;
	has Int  $.indent;
	has      $.align;

	my enum Align 	<< Left Right Middle >>;

	method space (:$indent = 2, :$align = Align::Left) {
		self.new(
			padding-char => makeKString(" ", 1),
			:$indent,
			:$align
		);
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
