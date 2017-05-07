
use Test;
use Terminal::Table;
use Terminal::Table::Style;
use Terminal::Table::Generator;

lives-ok {
    print-table([
        < a b c d e f g >,
        < h i j k l m n >,
        < o p q r s t >,
        < u v w x y z >,
    ]);
};

lives-ok {
    my $gen = create-generator([
        < a b c d e f g >,
        < h i j k l m n >,
        < o p q r s t >,
        < u v w x y z >,
    ]);

    $gen.generate();
    $gen.colour(1, 1, Color::String.new(color => <red>));
    $gen.colour(1, 5, Color::String.new(color => <blue underline>));
    $gen.print(:color);
};

lives-ok {
    my $gen = create-generator([
        < a b c d e f g >,
        < h i j k l m n >,
        < o p q r s t >,
        < u v w x y z >,
    ], style => Style.new(
        corner-style => Style::Corner.double(),
        line-style => Style::Line.single(),
        content-style => Style::Content.new(
            padding-left => 0,
            align => Align::RIGHT,
            padding-right => 4,
        ),
    ));
    $gen.generate();
    $gen.colour(1, 5, Color::String.new(color => <green>));
    $gen.colour(1, 1, Color::String.new(color => <blue underline>));
    $gen.print(:color);
};

done-testing;
