
use Test;

use Terminal::Table;
use Terminal::Table::Generator;
use Terminal::Table::VisitorHelper;

my @data = [
    [ "Language", "Example" ],
    [ "Chinese",  "你吃饭了吗？\n你好！\n你从哪里来？" ],
    [ "English",  "Nice to meet you!\nWhere are you from?" ],
    [ "Janpanese","ありがとうございます。\nいただきます！"],
    [ "Korean",   "안녕하세요！"],
];

my $gt = create-generator(@data);

$gt.generate();
$gt.hide(0);
$gt.hide(* - 1);
$gt.hide(0, :v);
$gt.hide(* - 1, :v);
my @array1 = $gt.to-array();
my @array2 = Array.new;
$gt.visit(
    h-frame => -> |c {
        my @ret = &visitor-helper().h-frame(|c);
        @array2.push(@ret) if +@ret > 0;
    },
    v-frame => -> |c {
        my @ret = &visitor-helper().v-frame(|c);
        for @ret -> $line {
            @array2.push(@$line) if +@$line > 0;
        }
    }
);

say "->", $_ for @array1;
say "=>", $_ for @array2;

for @array1 Z, @array2 -> ($o, $t) {
    ok($o eq $t, "Array item equal");
}

done-testing();
