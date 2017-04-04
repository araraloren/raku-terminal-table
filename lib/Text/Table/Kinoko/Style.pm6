
use v6;
use Text::Table::Kinoko::Char;

multi sub makeChar(Str $str) is export {
	return Char.new(
		str => $str
	);
}

multi sub makeChar(Str $str, Int $width) is export {
	return Char.new(
		str => $str,
		width => $width
	);
}

sub makeCharArray(@style) is export {
	my @ret;

	for @style -> $inner {
		my @t;
		@t.push(Char.new(
					   str => $_
				   )) for @$inner;
		@ret.push(@t);
	}
	return @ret;
}

enum Style::Type 	<< None Space Single Double >>;

class Style::Corner {
	has @.style handles < AT-POS >;
	has $.mode;

	method none() {
		self.new(
			style => makeCharArray([
				['',  '', ''],
				['',  '', ''],
				['',  '', ''],
			]),
			mode => Style::Type::None
		);
	}

	method space() {
		self.new(
			style => makeCharArray([
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
				style => makeCharArray([
	                <┏ ┳ ┓>,
	                <┣ ╋ ┫>,
	                <┗ ┻ ┛>,
	            ]),
				mode => Style::Type::Single
			);
		}
		if ?$bold1 {
			return self.new(
				style => makeCharArray([
	                <┍ ┰ ┑>,
	                <┝ ┿ ┥>,
	                <┕ ┸ ┙>,
	            ]),
				mode => Style::Type::Single
			);
		}
		if ?$bold2 {
			return self.new(
				style => makeCharArray([
	                <┎ ┯ ┒>,
	                <┠ ╂ ┨>,
	                <┖ ┷ ┚>,
	            ]),
				mode => Style::Type::Single
			);
		}
		return self.new(
			style => makeCharArray([
				<┌ ┬ ┐>,
				<├ ┼ ┤>,
				<└ ┴ ┘>,
			]),
			mode => Style::Type::Single
		);
	}

	method double(:$single, :$single1) {
		if ?$single {
			return self.new(
				style => makeCharArray([
	                <╒ ╤ ╕>,
	                <╞ ╪ ╡>,
	                <╘ ╧ ╛>,
	            ]),
				mode => Style::Type::Double
			);
		}
		if ?$single1 {
			return self.new(
				style => makeCharArray([
	                <╓ ╥ ╖>,
	                <╟ ╫ ╢>,
	                <╙ ╨ ╜>,
	            ]),
				mode => Style::Type::Double
			);
		}
		return self.new(
			style => makeCharArray([
                <╔ ╦ ╗>,
                <╠ ╬ ╣>,
                <╚ ╩ ╝>,
            ]),
			mode => Style::Type::Double
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
		$!mode == Type::None;
	}
}

class Style::Line {
	has Char $.top;
	has Char $.h-middle;
	has Char $.bottom;
	has Char $.left;
	has Char $.v-middle;
	has Char $.right;
	has      $.mode;

	method none() {
		self.new(
			top 		=> makeChar('', 0),
			h-middle 	=> makeChar('', 0),
			bottom 		=> makeChar('', 0),
			left 		=> makeChar('', 0),
			v-middle 	=> makeChar('', 0),
			right 		=> makeChar('', 0),
			mode => Style::Type::None
		);
	}

	method space() {
		self.new(
			top 		=> makeChar(' ', 1),
			h-middle 	=> makeChar(' ', 1),
			bottom 		=> makeChar(' ', 1),
			left 		=> makeChar(' ', 1),
			v-middle 	=> makeChar(' ', 1),
			right 		=> makeChar(' ', 1),
			mode 		=> Style::Type::Space
		)
	}

	multi method single(:$bold) {
		if ?$bold {
			return self.new(
				top 		=> makeChar('━', 1),
				h-middle 	=> makeChar('━', 1),
				bottom 		=> makeChar('━', 1),
				left 		=> makeChar('┃', 1),
				v-middle 	=> makeChar('┃', 1),
				right 		=> makeChar('┃', 1),
				mode 		=> Style::Type::Single
			);
		}
		return self.new(
			top 		=> makeChar('─', 1),
			h-middle 	=> makeChar('─', 1),
			bottom 		=> makeChar('─', 1),
			left 		=> makeChar('│', 1),
			v-middle 	=> makeChar('│', 1),
			right 		=> makeChar('│', 1),
			mode 		=> Style::Type::Single
		);
	}

	method double() {
		self.new(
			top 		=> makeChar('═', 1),
			h-middle 	=> makeChar('═', 1),
			bottom 		=> makeChar('═', 1),
			left 		=> makeChar('║', 1),
			v-middle 	=> makeChar('║', 1),
			right 		=> makeChar('║', 1),
			mode 		=> Style::Type::Double
		)
	}

	method dot() {
		self.new(
			top 		=> makeChar('╍', 1),
			h-middle 	=> makeChar('╍', 1),
			bottom 		=> makeChar('╍', 1),
			left 		=> makeChar('╏', 1),
			v-middle 	=> makeChar('╏', 1),
			right 		=> makeChar('╏', 1),
			mode 		=> Style::Type::Double2
		)
	}

	method dot2() {
		self.new(
			top 		=> makeChar('╍', 1),
			h-middle 	=> makeChar('╍', 1),
			bottom 		=> makeChar('╍', 1),
			left 		=> makeChar('╏', 1),
			v-middle 	=> makeChar('╏', 1),
			right 		=> makeChar('╏', 1),
			mode 		=> Style::Type::Double2
		)
	}

	method is-none() {
		$!mode == Style::Type::None;
	}
}

class Style::Content {
	has Char $.padding-char;
	has Int  $.indent;
	has      $.align;

	my enum Align 	<< Left Right Middle >>;

	method space (:$indent = 2, :$align = Align::Left) {
		self.new(
			padding-char => makeChar(" ", 1),
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
