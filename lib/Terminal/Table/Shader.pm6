
use v6;
use Terminal::ANSIColor;

unit class Shader;

multi method colour(Str $str, Str $style) {
    return colored($str, $style);
}

multi method colour(Str $str, $style) {
    return colored($str, $style.color-style());
}

method extract-style(Str $str) returns Str {
    my $style = uncolor($str);
    $style ~~ s/\s+reset//;
    $style;
}

method wipe-style(Str $str) returns Str {
    return colorstrip($str);
}
