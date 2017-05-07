
use v6;

class X::Kinoko::Error is Exception {
    has $.msg handles <Str>;

    method message() {
        $!msg;
    }
}

class X::Kinoko::Warning is Exception {
    has $.msg handles <Str>;

    method message() {
        $!msg;
    }
}