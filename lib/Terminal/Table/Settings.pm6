
use v6;

our $TABSTOP = 8;
our $DEBUG   = False;
our $ZERO-PADDING = ' ';
our $STYLE-CACHE = False;

sub tabstop() returns Int is export is rw {
    $TABSTOP;
}

sub debug() returns Bool is export is rw {
    $DEBUG;
}

sub zero-padding() returns Str is export is rw {
    $ZERO-PADDING;
}

sub style-cache() returns Bool is export is rw {
    $STYLE-CACHE;
}
