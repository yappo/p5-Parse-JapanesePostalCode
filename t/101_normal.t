use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

my $parser = make_parser
    qq{01101,"064  ","0640941","ﾎｯｶｲﾄﾞｳ","ｻｯﾎﾟﾛｼﾁｭｳｵｳｸ","ｱｻﾋｶﾞｵｶ","北海道","札幌市中央区","旭ケ丘",0,0,1,0,0,0},
    qq{13113,"151  ","1510064","ﾄｳｷｮｳﾄ","ｼﾌﾞﾔｸ","ｳｴﾊﾗ","東京都","渋谷区","上原",0,0,1,0,0,0},
    qq{13307,"19002","1900223","ﾄｳｷｮｳﾄ","ﾆｼﾀﾏｸﾞﾝﾋﾉﾊﾗﾑﾗ","ﾅﾝｺﾞｳ","東京都","西多摩郡檜原村","南郷",0,0,0,0,0,0};

# region_id, old_zip, zip, pref_kana, city_kana, town_kana, $pref, $city, $town, $is_multi_zip, $has_koaza_banchi, $has_chome, $is_multi_town, $update_status, $update_reason
subtest 'sapporo' => sub {
    my $row = $parser->fetch_obj;
    is($row->region_id, '01101');
    is($row->old_zip, '064  ');
    is($row->zip, '0640941');
    is($row->pref_kana, 'ホッカイドウ');
    is($row->city_kana, 'サッポロシチュウオウク');
    is($row->town_kana, 'アサヒガオカ');
    is($row->pref, '北海道');
    is($row->city, '札幌市中央区');
    is($row->town, '旭ケ丘');
    is($row->is_multi_zip, '0');
    is($row->has_koaza_banchi, '0');
    is($row->has_chome, '1');
    is($row->is_multi_town, '0');
    is($row->update_status, '0');
    is($row->update_reason, '0');
};

subtest 'shibuya' => sub {
    my $row = $parser->fetch_obj;
    is($row->region_id, '13113');
    is($row->old_zip, '151  ');
    is($row->zip, '1510064');
    is($row->pref_kana, 'トウキョウト');
    is($row->city_kana, 'シブヤク');
    is($row->town_kana, 'ウエハラ');
    is($row->pref, '東京都');
    is($row->city, '渋谷区');
    is($row->town, '上原');
    is($row->is_multi_zip, '0');
    is($row->has_koaza_banchi, '0');
    is($row->has_chome, '1');
    is($row->is_multi_town, '0');
    is($row->update_status, '0');
    is($row->update_reason, '0');
};

subtest 'hinohara' => sub {
    my $row = $parser->fetch_obj;
    is($row->region_id, '13307');
    is($row->old_zip, '19002');
    is($row->zip, '1900223');
    is($row->pref_kana, 'トウキョウト');
    is($row->city_kana, 'ニシタマグンヒノハラムラ');
    is($row->town_kana, 'ナンゴウ');
    is($row->pref, '東京都');
    is($row->city, '西多摩郡檜原村');
    is($row->town, '南郷');
    is($row->is_multi_zip, '0');
    is($row->has_koaza_banchi, '0');
    is($row->has_chome, '0');
    is($row->is_multi_town, '0');
    is($row->update_status, '0');
    is($row->update_reason, '0');
};

is($parser->fetch_obj, undef);

done_testing;
