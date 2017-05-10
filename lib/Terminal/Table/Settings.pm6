
use v6;

our $TABSTOP = 8;
our $DEBUG   = False;

sub tabstop() returns Int is export is rw {
    $TABSTOP;
}

sub debug() returns Bool is export is rw {
    $DEBUG;
}
