use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

my $parser = make_parser
    q{21207,"50137","5013701","ｷﾞﾌｹﾝ","ﾐﾉｼ","ﾐﾉｼﾉﾂｷﾞﾆﾊﾞﾝﾁｶﾞｸﾙﾊﾞｱｲ","岐阜県","美濃市","美濃市の次に番地がくる場合",0,0,0,0,0,0},
    q{20448,"39972","3997201","ﾅｶﾞﾉｹﾝ","ﾋｶﾞｼﾁｸﾏｸﾞﾝｲｸｻｶﾑﾗ","ｲｸｻｶﾑﾗﾉﾂｷﾞﾆﾊﾞﾝﾁｶﾞｸﾙﾊﾞｱｲ","長野県","東筑摩郡生坂村","生坂村の次に番地がくる場合",0,0,0,0,0,0},
    q{42212,"85724","8572427","ﾅｶﾞｻｷｹﾝ","ｻｲｶｲｼ","ｵｵｼﾏﾁｮｳﾉﾂｷﾞﾆﾊﾞﾝﾁｶﾞｸﾙﾊﾞｱｲ","長崎県","西海市","大島町の次に番地がくる場合",0,0,0,0,0,0};

do {
    my $row = $parser->fetch_obj;
    is($row->zip, '5013701');
    is($row->pref_kana, 'ギフケン');
    is($row->region_kana, 'ミノシ');
    is($row->town_kana, undef);
    is($row->pref, '岐阜県');
    is($row->region, '美濃市');
    is($row->town, undef);
};

do {
    my $row = $parser->fetch_obj;
    is($row->zip, '3997201');
    is($row->pref_kana, 'ナガノケン');
    is($row->region_kana, 'ヒガシチクマグンイクサカムラ');
    is($row->town_kana, undef);
    is($row->pref, '長野県');
    is($row->region, '東筑摩郡生坂村');
    is($row->town, undef);
};

do {
    my $row = $parser->fetch_obj;
    is($row->zip, '8572427');
    is($row->pref_kana, 'ナガサキケン');
    is($row->region_kana, 'サイカイシ');
    is($row->town_kana, 'オオシマチョウ');
    is($row->pref, '長崎県');
    is($row->region, '西海市');
    is($row->town, '大島町');
};

done_testing;
