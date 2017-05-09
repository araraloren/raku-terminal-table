
use v6;
use Terminal::ANSIColor;

unit class Shader;

multi method colour(Str $str, Str $style) {
    return colored($str, $style);
}

multi method colour(Str $str, $style) {
    return colored($str, $style.color-style());
}

method has-color(\str) returns Bool {
    my regex color-seq { \e\[\d+m };

    return str ~~ /<color-seq>/;
}

method extract-style(Str $str) returns Str {
    my $style = uncolor($str);
    $style ~~ s/\s+reset//;
    $style;
}

method wipe-style(Str $str) returns Str {
    return colorstrip($str);
}
