
use v6;
use Text::Table::Kinoko::Char;

enum Styler::Type << None Space Default Double Rounded >>;
enum Styler::Pos  <<  :Top(0) :Lower(2) :Left(0) :Middle(1) :Right(2) >>;

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

class Styler::Corner {
	has @.style handles < AT-POS >;
	has $.mode;

	method none() {
		self.new(mode => Styler::Type::None);
	}

	method default() {
		self.new(
			style => makeCharArray([
                <┌ ┬ ┐>,
                <├ ┼ ┤>,
                <└ ┴ ┘>,
            ]),
			mode => Styler::Type::Default
		);
	}
}

class Styler::Line {
	has Char $.top;
	has Char $.h-middle;
	has Char $.lower;
	has Char $.left;
	has Char $.v-middle;
	has Char $.right;
	has      $.mode;

	method none() {
		self.new(mode => Styler::Type::None);
	}

	method default() {
		self.new(
			top 		=> makeChar('─', 1),
			h-middle 	=> makeChar('─', 1),
			lower 		=> makeChar('─', 1),
			left 		=> makeChar('│', 1),
			v-middle 	=> makeChar('│', 1),
			right 		=> makeChar('│', 1),
			mode 		=> Styler::Type::Default
		)
	}
}

class Styler::Content {
	has Char $.padding-char;

	method new () {
		self.bless(
			padding-char => makeChar(" ", 1)
		);
	}
}

class Styler {
	has Styler::Corner	$.corner-styler;
	has Styler::Line	$.line-styler;
	has Styler::Content	$.content-styler;

	method corner {
		$!corner-styler;
	}

	method line {
		$!line-styler;
	}

	method content {
		$!content-styler;
	}
}
