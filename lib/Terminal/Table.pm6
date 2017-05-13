
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

    $generator.generate.print(:coloured);
}

sub array-to-table(@data, @max-widths = [], :$style = Style::Default::ASCII) is export {
    my $generator = create-generator(@data, :$style);

    $generator.generate.to-array(:coloured);
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

=head2 tabstop() returns Int is export is rw

Setting tab width, default is 8.

=head2 print-table(@data, @max-widths = [], :$style = Style::Default::ASCII)

=item @data

    Table data, is a two-dimension array.

=item @max-widths = []

    Maximum width of table column, is I<-1> when not set.

=item :$style = Style::Default::ASCII

    Table style, default is I<ASCII> style.

C<&print-table> generate a table and print it.

=head2 array-to-table(@data, @max-widths = [], :$style = Style::Default::ASCII)

=item @data

    Table data, is a two-dimension array.

=item @max-widths = []

    Maximum width of table column, is I<-1> when not set.

=item :$style = Style::Default::ASCII

    Table style, default is I<ASCII> style.

C<&array-to-table> generate a table for the given data and style.

=head2 create-generator(@data, :$style = Style::Default::ASCII)

=item @data

    Table data, is a two-dimension array.

=item :$style = Style::Default::ASCII

    Table style, default is I<ASCII> style.

C<&create-generator> create a C<Generator> for the given data and style.

=head2 visitor-helper(--> Generator::VisitorHelper)

Return a global instance of C<Generator::VisitorHelper>, it has some helper method
for visit table data.

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

=head3  generator(:&callback --> Generator::Table)

=item :&callback

    It will pass to C<set-callback> of C<Generator::Table>.

Return a instance of U<class Generator::Table>.

=head2 class Generator::Table

The real table generator, it copyed data and style from C<Generator>. It has a
C<@content> array store table content data, and a C<@frame> store table frame data.
One line of C<@content> corresponding two line in C<@frame>.

=head3 generate(@max-widths = [], :$coloured --> Generator::Table)

=item @max-widths = []

    The max width of every column, will be I<-1> when not set.

=item :$coloured

    When C<$coloured> is True, it'll colored string outputed.

Generate table data, it'll call C<&callback> setted through C<set-callback>.

=head3 set-callback(&callback --> Generator::Table)

=item &callback #`(:(@hframe, @vframe, @content, Bool $coloured))

    Will call in generate process, it will pass first horizonal-frame line、second
    vertical-frame line, and content data, also coloured for style generate. The
    C<@v-frame> and C<@@content> will empty when last line passed. You should call
    help method in C<&visitor-helper> when use this callback. Please refer
    L<sample/self-defined-style.p6> for sample.

Set callback for C<Generator::Table::generate>.

=head3 clear-callback( --> Generator::Table)

Clear callback.

=head3 row-count( --> Int)

Return row count of current table content data.

=head3 max-col-count( --> Int )

Return the maximum column count of table content data.

=head3 col-count( Int $index --> Int )

Return the column count of table content data in C<$index> line.

=head3 colour(Int $x, Int $y, Color::String $style, Int $row = 0 --> Generator::Table)

Set color style for C<$row> line of cell at coord (I<$x>, I<$y>) base on (zero, zero).

=head3 colour(Int $x, Int $y, Color::String $style --> Generator::Table)

Set color style for all line of cell at coord (I<$x>, I<$y>) base on (zero, zero).

=head3 hide(Int $index, :$v --> Generator::Table)

Hide one horizonal-frame line or vertical-frame line at C<$index>.

=head3 unhide(Int $index, :$v --> Generator::Table)

Unhide one horizonal-frame line or vertical-frame line at C<$index>.

=head3 to-array(Bool :$coloured = False, :$helper = &visitor-helper() --> Array)

Travel the table, return a array contains frame and content.

=head3 print(Bool :$coloured = False, :$helper = &visitor-helper())

Print the table.

=head3 visit-all(Bool $coloured = True, :&h-frame, :&v-frame)

=begin code

# ...
$foo.generate();
my &h-frame = sub (|c) {
    .print for @(&visitor-helper().h-frame(|c));
    "".say;
};
my &v-frame = sub (|c) {
    for @(&visitor-helper().v-frame(|c)) -> $line {
        .print for @($line);
        "".say;
    }
};
$foo.visit-all(:&h-frame, :&v-frame, True);

=end code

Ignore the visibility of frame, visit all data in table.

=head3 visit(Bool $coloured = True, :&h-frame, :&v-frame)

Visit the table data, call C<&h-frame> when access horizonal-frame line, and C<&v-frame>

for horizonal-frame line and content.

=end pod
