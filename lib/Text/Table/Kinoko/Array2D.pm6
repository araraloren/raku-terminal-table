
use v6;

class X::Array2D::OutOfRange is Exception { }

class Array2D {
	has Int $.elems = 0;
	has @!data;

	my class Array1D {
		has $.ref-a1d = [];

		method new(\a1d) {
			self.bless()!init(a1d);
		}

		method !init(\a1d) {
			$!ref-a1d := a1d;
			self;
		}

		method AT-POS(Int $pos) {
			return $!ref-a1d[$pos];
		}

		method ASSIGN-POS(Int $pos, $v) {
			$!ref-a1d[$pos] = $v;
		}

		method append(Array1D $a1d) {
			self.push($a1d[$_]) for 0 ...^ $a1d.elems;
		}

		method push($v) {
			$!ref-a1d.push($v);
		}

		method unshift($v) {
			$!ref-a1d.unshift($v);
		}

		method pop() {
			$!ref-a1d.pop();
		}

		method shift() {
			$!ref-a1d.shift();
		}

		method elems {
			return $!ref-a1d.elems;
		}
	}

	method AT-POS(Int $pos) {
		loop (my $i = $!elems;$i <= $pos; $i++) {
			@!data[$i] = [];
		}
		$!elems = $pos + 1 if $pos >= $!elems;
		my \a1d = @!data[$pos];
		return Array1D.new(a1d);
	}

	method perl() {
		return "(Array2D)" unless self.defined;
		return "Array2D.new(elems => {$!elems}, @!data => {@!data.perl})";
	}
}

class Array2D::Fixed {
	has Int $.elems = 0;
	has Int $.col-max;
	has @!data;

	method new($x, $y) {
		my @data = [];
		@data[$_] = [] for ^$x;
		self.bless(col-max => $y, data => @data);
	}

	my class Array1D {
		has $.ref-a1d;
		has $.col-max;

		method new(\a1d, :$col-max) {
			self.bless(:$col-max)!init(a1d);
		}

		method !init(\a1d) {
			$!ref-a1d := a1d;
			self;
		}

		method !__check_range($x) {
			if $x > $!col-max {
				X::Array2D::OutOfRange.new.throw();
			}
		}

		method AT-POS(Int $pos) {
			self.__check_range($pos);
			return $!ref-a1d[$pos];
		}

		method ASSIGN-POS(Int $pos, $v) {
			self.__check_range($pos);
			$!ref-a1d[$pos] = $v;
		}

		method append(Array1D $a1d) {
			self.push($a1d[$_]) for 0 ...^ $a1d.elems;
		}

		method push($v) {
			self.__check_range($!ref-a1d.elems + 1);
			$!ref-a1d.push($v);
		}

		method unshift($v) {
			self.__check_range($!ref-a1d.elems + 1);
			$!ref-a1d.unshift($v);
		}

		method pop() {
			$!ref-a1d.pop();
		}

		method shift() {
			$!ref-a1d.shift();
		}

		method elems {
			return $!ref-a1d.elems;
		}
	}

	method AT-POS(Int $pos) {
		if $pos >= @!data.elems {
			X::Array2D::OutOfRange.new.throw();
		}
		$!elems = $pos if $pos > $!elems;
		my \a1d = @!data[$pos];
		return Array1D.new( a1d, col-max => $!col-max );
	}

	method perl() {
		return "(Array2D::Fixed)" unless self.defined;
		return "Array2D::Fixed.new(elems => {$!elems}, col-max => {$!col-max}, @!data => {@!data.perl})";
	}
}
