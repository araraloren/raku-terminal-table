
use v6;
use Terminal::WCWidth;
use Text::Table::Kinoko::KString;

unit module LightWrap;

grammar String {
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

class String::Actions {
	has $.max;
	has $.line;
	has $.current;
	has $.force;
	has @!lines;

	method new(:$max!, :$force = False) {
		self.bless(:$max, :current(0), :line(""), :$force);
	}

	method other($/) {
		self.__concat_line($/.Str => wcswidth($/.Str));
	}

	method zh($/) {
		self.__concat_line($/.Str => wcswidth($/.Str));
	}

	method en($/) {
		my ($key, $value) = ($/.Str, wcswidth($/.Str));
		
		if $!force && $value > $!max {
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
			my $len = wcswidth($ch);
			if $!current + $len + 1 == $!max {
				@!lines.push($!line ~ $ch ~ '-');
				self.__reset();
			} else {
				($!line, $!current) = ($!line ~ $ch, $!current + $len);
			}
		}
	}

	multi method __concat_line(Pair $str) {
		if $!current + $str.value > $!max {
			@!lines.push($!line);
			self.__reset();
		} else {
			($!line, $!current) = ($!line ~ $str.key, $!current + $str.value);
		}
	}

	method lines() {
		if $!line ne "" {
			@!lines.push($!line);
			self.__reset();
		}
		@!lines;
	}
}

sub split-w(Str $str, Int $length, :$force = False) is export {
	String.parse($str, :actions(my $a = String::Actions.new(max => $length, :$force)));
	$a.lines();
}