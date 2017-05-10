
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
                corner-style => Style::Corner.single(),
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

    $generator.print(:color);
}

sub array-to-table(@data, @max-widths = [], :$style = Style::Default::ASCII) is export {
    my $generator = create-generator(@data, :$style);

    $generator.to-array(:color);
}


=begin pod

=head1 NAME

Terminal::Table - Advanced table generate module for perl6

=head1 SYNOPSIS

=begin code
use Terminal::Table;

my @data = [
    [ "Language", "Example" ],
    [ "Chinese",  "你吃饭了吗？\n你好！\n你从哪里来？" ],
    [ "English",  "Nice to meet you!\nWhere are you from?" ],
    [ "Janpanese","ありがとうございます。\nいただきます！"],
    [ "Korean",   "안녕하세요！"],
];

print-table(@data);
=end code

=head1 DESCRIPTION

Terminal::Table can generate ascii table or unicode table output
in terminals. It can be simple use high level interface C<&print-table>,
or use class C<Generator> in complex way.

=head2 C<print-table(@data, @max-widths = [], :$style = Style::Default::ASCII)>

=item @data

    Table data, is a two-dimension array.

=item @max-widths = []

    Maximum width of table column, is I<-1> when not set.

=item :$style = Style::Default::ASCII

    Table style, default is I<ASCII> style.

C<&print-table> generate a table and print it.

=head2 C<array-to-table(@data, @max-widths = [], :$style = Style::Default::ASCII)>

=item @data

    Table data, is a two-dimension array.

=item @max-widths = []

    Maximum width of table column, is I<-1> when not set.

=item :$style = Style::Default::ASCII

    Table style, default is I<ASCII> style.

C<&array-to-table> generate a table for the given data and style.

=head2 C<create-generator(@data, :$style = Style::Default::ASCII)>

=item @data

    Table data, is a two-dimension array.

=item :$style = Style::Default::ASCII

    Table style, default is I<ASCII> style.

C<&create-generator> create a C<Generator> for the given data and style.

=head2 class Generator

C<Generator> collect user data and style, then generate a table generator.

=head3 new(Style :$style is copy --> Generator)

Table style for current C<Generator>.

Create a instance of C<Generator> with given style.

=head3 add-cell(Str $str --> Generator)

Create a new cell in C<Generator>, and generate a C<Content> with C<$str>, then put
it into the cell.

=head3 add-cell(Str $str, Color::String $style --> Generator)

=item  Color::String $style

The style will be apply to the current cell's C<Content>.

Create a new cell in C<Generator>, and generate a C<Content> with C<$str> and C<$style>,
then put it into the cell.

=head3 add-cell(@lines --> Generator)

=item @lines

A multi line C<String> will be generate with C<@lines>.

Create a new cell, and generate a C<Content> with content C<@lines>, then put it
into the cell.

=head3 add-cell(@lines, Color::String $style --> Generator)

=item @lines

A multi line C<Content> will be generate with C<@lines>.

=item  Color::String $style

The style will be apply to the all line of C<Content>.

Create a new cell, and generate a C<Content> with C<@lines> and C<$style>,
then put it into the cell.

=head3 add-cell($maybestr where * !~~ Str --> Generator)

Create a new cell in C<Generator>, and generate a C<Content> with C<$maybestr>,
then put it into the cell.

=head3 add-cell($maybestr where * !~~ Str, Color::String $style --> Generator)

Create a new cell in C<Generator>, and generate a C<Content> with C<$maybestr>
and C<$style>, then put it into the cell.

=head3 end-line(--> Generator)

End current line and create a new line.

=head3 from-array(@array --> Generator)

Generate a C<Content> array with C<@array>, then append it into table data.

=head3 from-array(@array, @styles --> Generator)

Generate a C<Content> array with C<@array> and C<@styles>, then append it to
table data.

=head3 join(Generator $g, :$preserve-style, :$replace-style --> Generator)

Append data of C<$g> to current C<Generator>, the add style of C<$g> to current
C<Generator> if I<preserve-style> specified, or replace current style with style of
C<$g> if I<replace-style> specified.

=head3  generator(@max-widths = [] --> Generator::Table)

=item @max-widths = []

    The max width of every column, will be I<-1> when not set.

Return a instance of U<class Generator::Table>.

=end pod
