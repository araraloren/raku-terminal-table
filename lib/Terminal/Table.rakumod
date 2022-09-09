
use v6;
use Terminal::Table::Style;
use Terminal::Table::Generator;

sub create-generator(@data, :$style = Style::Default::ASCII) is export {
    my $gen-style = Style.default(:$style);

    my Generator $gen .= new(style => $gen-style);

    $gen.from-array(@data);
    $gen.generator();
}

sub print-table(@data, @max-widths = [], :$style = Style::Default::ASCII) is export {
    my $generator = create-generator(@data, :$style);

    $generator.generate.print(:coloured);
}

sub array-to-table(@data, @max-widths = [], :$style = Style::Default::ASCII) is export {
    my $generator = create-generator(@data, :$style);

    $generator.generate.to-array(:coloured);
}

