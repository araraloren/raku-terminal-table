
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

The result table:

    +---------+----------------------+
    |Language |Example               |
    +---------+----------------------+
    |Chinese  |你吃饭了吗？          |
    |         |你好！                |
    |         |你从哪里来？          |
    +---------+----------------------+
    |English  |Nice to meet you!     |
    |         |Where are you from?   |
    +---------+----------------------+
    |Janpanese|ありがとうございます。|
    |         |いただきます！        |
    +---------+----------------------+
    |Korean   |안녕하세요！          |
    +---------+----------------------+

=end code

=head1 DESCRIPTION

Terminal::Table can generate ascii table or unicode table output
in terminals. It can be simple use high level interface C<&print-table>,
or use class C<Generator> in complex way.

=head1 SUB

=head2 tabstop() returns Int is export is rw

Setting tab width, default is 8.

=head2 zero-padding() returns Str is export is rw

When handle empty Str, the generator will padding with C<&zero-padding()>.

=head2 style-cache() returns Bool is export is rw

If set at true, the C<Generator::Table> will use a cache instead of make clone of
every frame data. Attention these will cause bug when you want use C<&hide> modify
result table.

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

=head2 noexpand-width(Str $str --> Int)

Call C<Terminal::WCWidth::wcswidth> with C<$str>, and return the width.

=head2 expand-width(Str $str --> Int)

Expand C<$str> through C<Text::Tabs::expand>, and call C<Terminal::WCWidth::wcswidth>
with expanded string, and return the width.

=head1 CLASS

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
    C<@v-frame> and C<@content> will empty when last line passed. You should call
    help method through C<&visitor-helper> when use this callback. Please refer
    L<sample/self-defined-style.p6> for sample.

Set callback for C<Generator::Table::generate>.

=head3 clear-callback( --> Generator::Table)

Clear callback.

=head3 Int

Return row count of current table content data.

=head3 row-count( --> Int)

Return row count of current table content data.

=head3 max-col-count( --> Int )

Return the maximum column count of table content data.

=head3 col-count( Int $index --> Int )

Return the column count of table content data in C<$index> line.

=head3 colour(Int $r, Int $c, Color::String $style, Int $row = 0 --> Generator::Table)

Set color style for C<$row> line of cell (at row I<$r>, column I<$c>) base on (zero, zero).

=head3 colour(Int $r, Int $c, Color::String $style --> Generator::Table)

Set color style for all line of cell (at row I<$r>, column I<$c>) base on (zero, zero).

=head3 hide and unhide

The result table:

    [ + -- + -- + ]
    [ | xx | xx | ]
    [ + -- + -- + ]
    [ | xx | xx | ]
    [ + -- + -- + ]

C<hide> and C<unhide> apply on result table. You can hide one row or one column,
even one element of result table (frame or content("xx" in the table)).

The C<$r> and C<$c> is row index and column index of result table element;

=head3 hide(Int $index, :$v --> Generator::Table)

Hide C<$index> row of result table.

=head3 hide(Int $r, Int $c --> Generator::Table)

Hide C<$c> column in the C<$r> row of the result table.

=head3 unhide(Int $index, :$v --> Generator::Table)

Unhide C<$index> row of result table.

=head3 unhide(Int $r, Int $c --> Generator::Table)

Unhide C<$c> column in the C<$r> row of the result table.

=head3 is-hidden(Int $r, Int $c, :$v --> Generator::Table)

Rerturn True if C<$c> column in C<$r> row of result table is hidden.

=head3 to-array(Bool :$coloured = False, :$helper = &visitor-helper() --> Array)

Travel the table, return a array contains frame and content.

=head3 print(Bool :$coloured = False, :$helper = &visitor-helper())

Print the table.

=head3 visit(Bool $coloured = True, :&h-frame, :&v-frame)

=item :&h-frame ~~ & (@h-frame, Bool $coloured)

=item :&v-frame ~~ & (@v-frame, @contents, Bool $coloured)

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
$foo.visit(:&h-frame, :&v-frame, True);

=end code

Visit the table data, call C<&h-frame> when access horizonal-frame line, and C<&v-frame>
for horizonal-frame line and content. In your callback, you can use some helper
method  through C<&visitor-helper>.

=head2 class VisitorHelper

=head3 visitor-helper( --> VisitorHelper) is export is rw

Return a instance of C<VisitorHelper>. It has some helper method for process table
data.

=head3 h-frame(@h-frame, Bool $coloured --> Array)

Return string of the horizonal-frame as an array. The coloured is ignore.

=head3 v-frame(@v-frame, @contents, Bool $coloured --> Array)

Return string of the vertical-frame as an array. When coloured is set, string will
format according style. When style is none, only string of C<@contents> will be
return.

=head3 generate(@h-frame, @v-frame, @contents, Bool $coloured --> Array)

Return string of horizonal-frame or vertical-frame as an array like C<h-frame> or
C<v-frame> does.

=head2 enum Style::Default

The style use unicode character except none, ascii and space, other style.

=item NONE

The none style.

=item ASCII

The ascii style, is common used style.

=item SPACE

The space style.

=item DOT

The dot style, only line has dot style.

=item SINGLE

The single style.

=item DOUBLE

The double style.

=item ROUND

The round style, only corner has round style.

=item OTHER

User define style.

=head2 class Style::Corner

The C<Style::Corner> represent style of table corner, and you can defined your
own style.

=head3 method new(:@style, :$mode)

=item :@style

    The style is a two dimension array, such as:

    ['+', '+', '+']
    ['+', '+', '+']
    ['+', '+', '+']

=head3 default style

Return the style count when C<$count> is set, or return a style instance according
C<$index>. By default, the index is 0.

=item method none(Int $index, :$count)

    This style has 1 default style.

    Style 0

    ['',  '', '']
    ['',  '', '']
    ['',  '', '']

    No corner style, attention this only used in concert with C<Style::Line::none>.

=item method space(Int $index, :$count)

    This style has 1 default style.

    Style 0

    [' ', ' ', ' ']
    [' ', ' ', ' ']
    [' ', ' ', ' ']

=item method ascii(Int $index, :$count)

    This style has 1 default style.

    Style 0

    <+ + +>,
    <+ + +>,
    <+ + +>,

=item method single(Int $index, :$count)

    This style has 4 default style.

    Style 0

    <┌ ┬ ┐>,
    <├ ┼ ┤>,
    <└ ┴ ┘>,

    Style 1

    <┏ ┳ ┓>,
    <┣ ╋ ┫>,
    <┗ ┻ ┛>,

    Style 2

    <┍ ┰ ┑>,
    <┝ ┿ ┥>,
    <┕ ┸ ┙>,

    Style 3

    <┎ ┯ ┒>,
    <┠ ╂ ┨>,
    <┖ ┷ ┚>,

=item method double(Int $index, :$count)

    This style has 3 default style.

    Style 0

    <╔ ╦ ╗>,
    <╠ ╬ ╣>,
    <╚ ╩ ╝>,

    Style 1

    <╒ ╤ ╕>,
    <╞ ╪ ╡>,
    <╘ ╧ ╛>,

    Style 2

    <╓ ╥ ╖>,
    <╟ ╫ ╢>,
    <╙ ╨ ╜>,

=item method round(Int $index, :$count)

    This style has 2 default style.

    Style 0

    <╭ ╦ ╮>,
    <╠ ╬ ╣>,
    <╰ ╩ ╯>,

    Style 1

    <╭ ┬ ╮>,
    <├ ┼ ┤>,
    <╰ ┴ ╯>,

=head2 class Style::Line

The C<Style::Line> represent style of table line, also you can define you own style.

=head3 method new(:$mode, *%args)

=item *%args

    The C<*%args> is a hash which contains line style. Every style must have their
    string and width. You can use C<&expand-width> get width. such as:

    Style::Line.new(
        top 		=> ['', 0],
        h-middle 	=> ['', 0],
        bottom 		=> ['', 0],
        left 		=> ['', 0],
        v-middle 	=> ['', 0],
        right 		=> ['', 0],
        mode 		=> NONE
    )

Return a instance of C<Style::Line>.

=head3 default style

Return the style count when C<$count> is set, or return a style instance according
C<$index>. By default, the index is 0.

=item method none(Int $index, :$count)

    This style has 1 default style.

    Style 0

    top 	=> ['', 0],
    h-middle 	=> ['', 0],
    bottom 	=> ['', 0],
    left 	=> ['', 0],
    v-middle 	=> ['', 0],
    right 	=> ['', 0],
    mode 	=> NONE

    No line style, attention this only used in concert with C<Style::Corner::none>.

=item method ascii(Int $index, :$count)

    This is style has 1 default style.

    Style 0

    top 	=> ['-', 1],
    h-middle 	=> ['-', 1],
    bottom 	=> ['-', 1],
    left 	=> ['|', 1],
    v-middle 	=> ['|', 1],
    right 	=> ['|', 1],
    mode 	=> ASCII

    *----*----*
    |    |    |
    *----*----*
    |    |    |
    *----*----*

=item method space(Int $index, :$count)

    This is style has 1 default style.

    Style 0

    top 	=> [' ', 1],
    h-middle 	=> [' ', 1],
    bottom 	=> [' ', 1],
    left 	=> [' ', 1],
    v-middle 	=> [' ', 1],
    right 	=> [' ', 1],
    mode 	=> SPACE

    *    *    *

    *    *    *

    *    *    *

=item method single(Int $index, :$count)

    This is style has 4 default style.

    Style 0

    top 	=> ['─', 1],
    h-middle 	=> ['─', 1],
    bottom 	=> ['─', 1],
    left 	=> ['│', 1],
    v-middle 	=> ['│', 1],
    right 	=> ['│', 1],
    mode 	=> SINGLE

    *────*────*
    │    │    │
    *────*────*
    │    │    │
    *────*────*

    Style 1

    top 	=> ['━', 1],
    h-middle 	=> ['━', 1],
    bottom 	=> ['━', 1],
    left 	=> ['┃', 1],
    v-middle 	=> ['┃', 1],
    right 	=> ['┃', 1],
    mode 	=> SINGLE

    *━━━━*━━━━*
    ┃    ┃    ┃
    *━━━━*━━━━*
    ┃    ┃    ┃
    *━━━━*━━━━*

    Style 2

    top 	=> ['╼', 1],
    h-middle 	=> ['╼', 1],
    bottom 	=> ['╼', 1],
    left 	=> ['╽', 1],
    v-middle 	=> ['╽', 1],
    right 	=> ['╽', 1],
    mode 	=> SINGLE

    *╼╼╼╼*╼╼╼╼*
    ╽    ╽    ╽
    *╼╼╼╼*╼╼╼╼*
    ╽    ╽    ╽
    *╼╼╼╼*╼╼╼╼*

    Style 3

    top 	=> ['╾', 1],
    h-middle 	=> ['╾', 1],
    bottom 	=> ['╾', 1],
    left 	=> ['╿', 1],
    v-middle 	=> ['╿', 1],
    right 	=> ['╿', 1],
    mode 	=> SINGLE

    *╾╾╾╾*╾╾╾╾*
    ╿    ╿    ╿
    *╾╾╾╾*╾╾╾╾*
    ╿    ╿    ╿
    *╾╾╾╾*╾╾╾╾*

=item method double(Int $index, :$count)

    This is style has 1 default style.

    Style 0

    top 	=> ['═', 1],
    h-middle 	=> ['═', 1],
    bottom 	=> ['═', 1],
    left 	=> ['║', 1],
    v-middle 	=> ['║', 1],
    right 	=> ['║', 1],
    mode 	=> DOUBLE

    *════*════*
    ║    ║    ║
    *════*════*
    ║    ║    ║
    *════*════*

=item method dot(Int $index, :$count)

    This is style has 6 default style.

    Style 0

    top 	=> ['╌', 1],
    h-middle 	=> ['╌', 1],
    bottom 	=> ['╌', 1],
    left 	=> ['╎', 1],
    v-middle 	=> ['╎', 1],
    right 	=> ['╎', 1],
    mode 	=> DOT

    *╌╌╌╌*╌╌╌╌*
    ╎    ╎    ╎
    *╌╌╌╌*╌╌╌╌*
    ╎    ╎    ╎
    *╌╌╌╌*╌╌╌╌*

    Style 1

    top 	=> ['╍', 1],
    h-middle 	=> ['╍', 1],
    bottom 	=> ['╍', 1],
    left 	=> ['╏', 1],
    v-middle 	=> ['╏', 1],
    right 	=> ['╏', 1],
    mode 	=> DOT

    *╍╍╍╍*╍╍╍╍*
    ╏    ╏    ╏
    *╍╍╍╍*╍╍╍╍*
    ╏    ╏    ╏
    *╍╍╍╍*╍╍╍╍*

    Style 2

    top 	=> ['┅', 1],
    h-middle 	=> ['┅', 1],
    bottom 	=> ['┅', 1],
    left 	=> ['┇', 1],
    v-middle 	=> ['┇', 1],
    right 	=> ['┇', 1],
    mode 	=> DOT

    *┅┅┅┅*┅┅┅┅*
    ┇    ┇    ┇
    *┅┅┅┅*┅┅┅┅*
    ┇    ┇    ┇
    *┅┅┅┅*┅┅┅┅*

    Style 3

    top 	=> ['┄', 1],
    h-middle 	=> ['┄', 1],
    bottom 	=> ['┄', 1],
    left 	=> ['┆', 1],
    v-middle 	=> ['┆', 1],
    right 	=> ['┆', 1],
    mode 	=> DOT

    *┄┄┄┄*┄┄┄┄*
    ┆    ┆    ┆
    *┄┄┄┄*┄┄┄┄*
    ┆    ┆    ┆
    *┄┄┄┄*┄┄┄┄*

    Style 4

    top 	=> ['┈', 1],
    h-middle 	=> ['┈', 1],
    bottom 	=> ['┈', 1],
    left 	=> ['┊', 1],
    v-middle 	=> ['┊', 1],
    right 	=> ['┊', 1],
    mode 	=> DOT

    *┈┈┈┈*┈┈┈┈*
    ┊    ┊    ┊
    *┈┈┈┈*┈┈┈┈*
    ┊    ┊    ┊
    *┈┈┈┈*┈┈┈┈*

    Style 5

    top 	=> ['┉', 1],
    h-middle 	=> ['┉', 1],
    bottom 	=> ['┉', 1],
    left 	=> ['┋', 1],
    v-middle 	=> ['┋', 1],
    right 	=> ['┋', 1],
    mode 	=> DOT

    *┉┉┉┉*┉┉┉┉*
    ┋    ┋    ┋
    *┉┉┉┉*┉┉┉┉*
    ┋    ┋    ┋
    *┉┉┉┉*┉┉┉┉*

=head2 enum Align

This defined how a string of a cell aligned. This algin and padding of C<Style::Content>
are independent. The padding width of algin is the difference between the width of
string and C<max-width> set by user, and subtract the padding-width of C<Style::Content>.
The padding of C<Style::Content> will append after align.

=item LEFT

Align left, the padding of content will append to right.

=item RIGHT

Align right, the padding of content will append to left.

=item MIDDLE

Align middle, the padding of content will append to both sides.

=head2 class Style::Content

=head3 method new(*%args)

=item String :$padding-char = String.new(value => " ", width => 1)

The character used for padding and align. Default is space.

=item Int :$padding-left = 0

The left padding count after algin, default is 0.

=item Int :$padding-right = 0

The right padding count after algin, default is 0.

=item :$algin = Align::LEFT

The algin style of content, default is Align::LEFT.

=item :$split-word = False

Will split word use connector '-' when set to True. It's only use in space-delimited
language such as english.

=head3 default style

=item method space()

This use default style, the padding-char is space.

=head2 class Style

This represent the style of whole table.

=head3 method new(*%args)

=item Style::Corner :$corner-style

The style of table corner.

=item Style::Line :$line-style

The style of table line.

=item Style::Content :$content-style

The style of table content.

=head3 default(:$style = Style::Default::ASCII)

Return a default style according C<$style>.

=item Style::Default::ASCII

    corner-style => Style::Corner.ascii(),
    line-style => Style::Line.ascii(),
    content-style => Style::Content.space(),

=item Style::Default::SINGLE

    corner-style => Style::Corner.single(),
    line-style => Style::Line.single(),
    content-style => Style::Content.space(),

=item Style::Default::NONE

    corner-style => Style::Corner.none(),
    line-style => Style::Line.none(),
    content-style => Style::Content.space(),

=item Style::Default::SPACE

    corner-style => Style::Corner.space(),
    line-style => Style::Line.space(),
    content-style => Style::Content.space(),

=item  Style::Default::DOUBLE

    corner-style => Style::Corner.double(),
    line-style => Style::Line.double(),
    content-style => Style::Content.space(),

=item Style::Default::DOT

    corner-style => Style::Corner.single(),
    line-style => Style::Line.dot(),
    content-style => Style::Content.space(),

=item Style::Default::ROUND

    corner-style => Style::Corner.round(),
    line-style => Style::Line.single(),
    content-style => Style::Content.space(),

=head2 class Color::String

This represent string color style. It used style from C<Terminal::ANSIColor>.

=head3 method new(*%args)

=item :@color

The style array of string. Such as <red underline>.

=item :$enabled = True

Default is enabled.

=end pod
