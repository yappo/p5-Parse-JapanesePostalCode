use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

my $parser = make_parser
    q{13362,"10003","1000301","ﾄｳｷｮｳﾄ","ﾄｼﾏﾑﾗ","ﾄｼﾏﾑﾗｲﾁｴﾝ","東京都","利島村","利島村一円",0,0,0,0,0,0},
    q{47356,"90136","9013601","ｵｷﾅﾜｹﾝ","ｼﾏｼﾞﾘｸﾞﾝﾄﾅｷｿﾝ","ﾄﾅｷｿﾝｲﾁｴﾝ","沖縄県","島尻郡渡名喜村","渡名喜村一円",0,0,0,0,0,0},
    q{25443,"52203","5220317","ｼｶﾞｹﾝ","ｲﾇｶﾐｸﾞﾝﾀｶﾞﾁｮｳ","ｲﾁｴﾝ","滋賀県","犬上郡多賀町","一円",0,0,0,0,0,0};

do {
    my $row = $parser->fetch_obj;
    is($row->zip, '1000301');
    is($row->town, undef);
    is($row->town_kana, undef);
};
do {
    my $row = $parser->fetch_obj;
    is($row->zip, '9013601');
    is($row->town, undef);
    is($row->town_kana, undef);
};
do {
    my $row = $parser->fetch_obj;
    is($row->zip, '5220317');
    is($row->town, '一円');
    is($row->town_kana, 'イチエン');
};

done_testing;
