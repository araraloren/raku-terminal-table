
use Terminal::Table;

my @data = [
    [ "Language", "Example" ],
    [ "Chinese",  "你吃饭了吗？\n你好！\n你从哪里来？" ],
    [ "English",  "Nice to meet you!\nWhere are you from?" ],
    [ "Janpanese","ありがとうございます。\nいただきます！"],
    [ "Korean",   "안녕하세요！"],
];

print-table(@data, [-1, 5]);
