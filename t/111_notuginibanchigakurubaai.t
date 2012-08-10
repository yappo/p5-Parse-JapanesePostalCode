use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

my $parser = make_parser
    q{21207,"50137","5013701","ｷﾞﾌｹﾝ","ﾐﾉｼ","ﾐﾉｼﾉﾂｷﾞﾆﾊﾞﾝﾁｶﾞｸﾙﾊﾞｱｲ","岐阜県","美濃市","美濃市の次に番地がくる場合",0,0,0,0,0,0},
    q{20448,"39972","3997201","ﾅｶﾞﾉｹﾝ","ﾋｶﾞｼﾁｸﾏｸﾞﾝｲｸｻｶﾑﾗ","ｲｸｻｶﾑﾗﾉﾂｷﾞﾆﾊﾞﾝﾁｶﾞｸﾙﾊﾞｱｲ","長野県","東筑摩郡生坂村","生坂村の次に番地がくる場合",0,0,0,0,0,0};

do {
    my $row = $parser->fetch_obj;
    is($row->zip, '5013701');
    is($row->pref_kana, 'ギフケン');
    is($row->city_kana, 'ミノシ');
    is($row->town_kana, undef);
    is($row->pref, '岐阜県');
    is($row->city, '美濃市');
    is($row->town, undef);
};

do {
    my $row = $parser->fetch_obj;
    is($row->zip, '3997201');
    is($row->pref_kana, 'ナガノケン');
    is($row->city_kana, 'ヒガシチクマグンイクサカムラ');
    is($row->town_kana, undef);
    is($row->pref, '長野県');
    is($row->city, '東筑摩郡生坂村');
    is($row->town, undef);
};

done_testing;
