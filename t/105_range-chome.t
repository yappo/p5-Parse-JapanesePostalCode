use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

my $parser = make_parser
    q{01101,"060  ","0600042","ﾎｯｶｲﾄﾞｳ","ｻｯﾎﾟﾛｼﾁｭｳｵｳｸ","ｵｵﾄﾞｵﾘﾆｼ(1-19ﾁｮｳﾒ)","北海道","札幌市中央区","大通西（１〜１９丁目）",1,0,1,0,0,0};

subtest 'other' => sub {
    my $row = $parser->fetch_obj;
    is($row->town, '大通西');
    is($row->town_kana, 'オオドオリニシ');
    ok($row->has_subtown);
    is(ref($row->subtown), 'ARRAY');
    is(ref($row->subtown_kana), 'ARRAY');
    my $subtown = [ $row->get_subtown_list ];
    is_deeply($subtown, [
        '1丁目',
        '2丁目',
        '3丁目',
        '4丁目',
        '5丁目',
        '6丁目',
        '7丁目',
        '8丁目',
        '9丁目',
        '10丁目',
        '11丁目',
        '12丁目',
        '13丁目',
        '14丁目',
        '15丁目',
        '16丁目',
        '17丁目',
        '18丁目',
        '19丁目',
    ]);
    my $subtown_kana = [ $row->get_subtown_kana_list ];
    is_deeply($subtown_kana, [
        '1チョウメ',
        '2チョウメ',
        '3チョウメ',
        '4チョウメ',
        '5チョウメ',
        '6チョウメ',
        '7チョウメ',
        '8チョウメ',
        '9チョウメ',
        '10チョウメ',
        '11チョウメ',
        '12チョウメ',
        '13チョウメ',
        '14チョウメ',
        '15チョウメ',
        '16チョウメ',
        '17チョウメ',
        '18チョウメ',
        '19チョウメ',
    ]);
};

done_testing;
