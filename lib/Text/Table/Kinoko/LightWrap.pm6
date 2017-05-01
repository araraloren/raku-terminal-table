
use v6;
use Text::Tabs;
use Text::Table::Kinoko::String;

unit module LightWrap;

grammar Sentence {
	token TOP {
		[ <zh> | <en> | <other> ]+
	}

	token other {
		<!zh> <!en> .
	}

	token zh {
		<:Block("CJK Unified Ideographs")>
	}

	token en {
		<:L>+
	}
}

class Sentence::Actions {
	has $.max;
	has $.line;
	has $.current;
	has $.force;
	has @!lines;

	method new(:$max!, :$force = False) {
		self.bless(:$max, :current(0), :line(""), :$force);
	}

	method other($/) {
		self.__concat_line($/.Str => noexpand-width($/.Str));
	}

	method zh($/) {
		self.__concat_line($/.Str => noexpand-width($/.Str));
	}

	method en($/) {
		my ($key, $value) = ($/.Str, noexpand-width($/.Str));

		if $!force && ($value > $!max || ($value + $!current > $!max)) {
			self.__concat_line($key.comb());
		} else {
			self.__concat_line($key => $value);
		}
	}

	method __reset() {
		($!line, $!current) = ("", 0);
	}

	multi method __concat_line(@ens) {
		for @ens -> $ch {
			my $len = noexpand-width($ch);
			if $!current + $len + 1 == $!max {
				self.__push($!line ~ $ch ~ '-');
				self.__reset();
			}
			($!line, $!current) = ($!line ~ $ch, $!current + $len);
		}
	}

	multi method __concat_line(Pair $str) {
		if $!current + $str.value > $!max {
			self.__push($!line);
			self.__reset();
		}
		($!line, $!current) = ($!line ~ $str.key, $!current + $str.value);
	}

	method __push(Str $str) {
		@!lines.push(String.new(str => $str, width => noexpand-width($str)));
	}

	method lines() {
		if $!line ne "" {
			self.__push($!line);
			self.__reset();
		}
		@!lines;
	}
}

sub split-w($str, Int $length, :$force = False) {
	Sentence.parse($str, :actions(my $a = Sentence::Actions.new(max => $length, :$force)));
	$a.lines();
}

multi sub wrap(String $str, Int :$max-width, Int :$tabstop, Bool :$force = False) is export {
	my @ret = [];
	@ret.append(split-w($_, $max-width, :$force)) for @(expand(split(/\n/, $str), $tabstop));
	return @ret>>.unexpand;
}

multi sub wrap(@strs, Int :$max-width, Int :$tabstop, Bool :$force = False) is export {
	my @ret = [];
	for @strs -> $str {
		@ret.append(split-w($_, $max-width, :$force)) for @(expand(split(/\n/, $str), $tabstop));
	}
	return @ret>>.unexpand;
}
