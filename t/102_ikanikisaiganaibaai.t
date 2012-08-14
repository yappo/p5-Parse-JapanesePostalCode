use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

my $parser = make_parser q{13113,"150  ","1500000","ﾄｳｷｮｳﾄ","ｼﾌﾞﾔｸ","ｲｶﾆｹｲｻｲｶﾞﾅｲﾊﾞｱｲ","東京都","渋谷区","以下に掲載がない場合",0,0,0,0,0,0};
my $row = $parser->fetch_obj;
is($row->zip, '1500000');
is($row->pref_kana, 'トウキョウト');
is($row->region_kana, 'シブヤク');
is($row->town_kana, undef);
is($row->pref, '東京都');
is($row->region, '渋谷区');
is($row->town, undef);

done_testing;
