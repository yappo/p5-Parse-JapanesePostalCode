use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

my $parser = make_parser
    q{01106,"005  ","0050030","ﾎｯｶｲﾄﾞｳ","ｻｯﾎﾟﾛｼﾐﾅﾐｸ","ﾐﾅﾐ30ｼﾞｮｳﾆｼ(8ﾁｮｳﾒ)","北海道","札幌市南区","南三十条西（８丁目）",0,0,1,0,0,0},
    q{01207,"080  ","0800848","ﾎｯｶｲﾄﾞｳ","ｵﾋﾞﾋﾛｼ","ｼﾞﾕｳｶﾞｵｶ(1､2ﾁｮｳﾒ)","北海道","帯広市","自由が丘（１、２丁目）",1,0,1,0,0,0},
    q{01101,"060  ","0600042","ﾎｯｶｲﾄﾞｳ","ｻｯﾎﾟﾛｼﾁｭｳｵｳｸ","ｵｵﾄﾞｵﾘﾆｼ(1-19ﾁｮｳﾒ)","北海道","札幌市中央区","大通西（１〜１９丁目）",1,0,1,0,0,0};

subtest 'single' => sub {
    my $row = $parser->fetch_obj;
    is($row->town, '南三十条西');
    is($row->town_kana, 'ミナミ30ジョウニシ');
    ok($row->has_subtown);
    is($row->subtown->[0], '8丁目');
    is($row->subtown_kana->[0], '8チョウメ');
};

subtest 'split' => sub {
    my $row = $parser->fetch_obj;
    is($row->town, '自由が丘');
    is($row->town_kana, 'ジユウガオカ');
    ok($row->has_subtown);
    is($row->subtown->[0], '1丁目');
    is($row->subtown_kana->[0], '1チョウメ');
    is($row->subtown->[1], '2丁目');
    is($row->subtown_kana->[1], '2チョウメ');
};

subtest 'range' => sub {
    my $row = $parser->fetch_obj;
    is($row->town, '大通西');
    is($row->town_kana, 'オオドオリニシ');
    ok($row->has_subtown);
    is_deeply($row->subtown, [
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
    is_deeply($row->subtown_kana, [
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
