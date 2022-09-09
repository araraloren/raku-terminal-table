
use Test;
use Terminal::Table;
use Terminal::Table::Style;
use Terminal::Table::Generator;

my @corners = < space ascii single double round >;
my @lines = < space ascii single dot double >;

my (@all-corner, @all-lines);

@all-corner.push(Style::Corner.none());
@all-lines.push(Style::Line.none());
for @corners -> $corner {
    for ^ Style::Corner."$corner"(:count) {
        @all-corner.push(Style::Corner."$corner"($_));
    }
}
for @lines -> $line {
    for ^ Style::Line."$line"(:count) {
        @all-lines.push(Style::Line."$line"($_));
    }
}

my $count = 0;

for @all-corner X, @all-lines -> ($c, $l) {
    if $c.is-none() && $l.is-none() || !$c.is-none() && !$l.is-none() {
        lives-ok {
            my $gen = create-generator([
                < a b c d e f g >,
                < h i j k l m n >,
                < o p q r s t >,
                < u v w x y z >,
            ], style => Style.new(
                corner-style => $c,
                line-style => $l,
                content-style => Style::Content.space(),
            ));

            $gen.generate();
            $gen.colour(1, 1, Color::String.new(color => <red>));
            $gen.colour(1, 5, Color::String.new(color => <blue underline>));
            $gen.print(:coloured);
        }, "style combination {++$count} ok";
    }
}

done-testing();
