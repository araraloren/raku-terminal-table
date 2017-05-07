
use v6;
use Terminal::Table::Style;
use Terminal::Table::Generator;

sub create-generator(@data, :$style = Style::Default::ASCII) is export {
    my $gen-style = do
    given $style {
        when Style::Default::ASCII {
            Style.new(
                corner-style => Style::Corner.ascii(),
                line-style => Style::Line.ascii(),
                content-style => Style::Content.space(),
            );
        }
        when Style::Default::SINGLE {
            Style.new(
                corner-style => Style::Corner.single(),
                line-style => Style::Line.single(),
                content-style => Style::Content.space(),
            );
        }
        when Style::Default::NONE {
            Style.new(
                corner-style => Style::Corner.none(),
                line-style => Style::Line.none(),
                content-style => Style::Content.space(),
            );
        }
        when Style::Default::SPACE {
            Style.new(
                corner-style => Style::Corner.space(),
                line-style => Style::Line.space(),
                content-style => Style::Content.space(),
            );
        }
        when Style::Default::DOUBLE {
            Style.new(
                corner-style => Style::Corner.double(),
                line-style => Style::Line.double(),
                content-style => Style::Content.space(),
            );
        }
        when Style::Default::DOT {
            Style.new(
                corner-style => Style::Corner.dot(),
                line-style => Style::Line.dot(),
                content-style => Style::Content.space(),
            );
        }
        when Style::Default::ROUND {
            Style.new(
                corner-style => Style::Corner.round(),
                line-style => Style::Line.single(),
                content-style => Style::Content.space(),
            );
        }
        default {
            unless $style.defined {
                X::Kinoko::Error.new(msg => 'Not recognize style.').throw();
            }
            $style;
        }
    };
    my Generator $gen .= new(style => $gen-style);

    $gen.from-array(@data);
    $gen.generator();
}

sub print-table(@data, @max-widths = [], :$style = Style::Default::ASCII) is export {
    my $generator = create-generator(@data, :$style);

    $generator.generate(@max-widths);
    $generator.print(:color);
}

sub array-to-table(@data, @max-widths = [], :$style = Style::Default::ASCII) is export {
    my $generator = create-generator(@data, :$style);

    $generator.generate(@max-widths);
    $generator.to-array(:color);
}
