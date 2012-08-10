use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

my $parser = make_parser
    q{01106,"005  ","0050865","ﾎｯｶｲﾄﾞｳ","ｻｯﾎﾟﾛｼﾐﾅﾐｸ","ﾄｷﾜ(1-131ﾊﾞﾝﾁ)","北海道","札幌市南区","常盤（１〜１３１番地）",1,0,0,0,0,0},
    q{01106,"005  ","0050840","ﾎｯｶｲﾄﾞｳ","ｻｯﾎﾟﾛｼﾐﾅﾐｸ","ﾌｼﾞﾉ(400､400-2ﾊﾞﾝﾁ)","北海道","札幌市南区","藤野（４００、４００−２番地）",1,0,0,0,0,0},
    q{01106,"005  ","0050008","ﾎｯｶｲﾄﾞｳ","ｻｯﾎﾟﾛｼﾐﾅﾐｸ","ﾏｺﾏﾅｲ(17ﾊﾞﾝﾁ)","北海道","札幌市南区","真駒内（１７番地）",1,0,0,0,0,0},
    q{01204,"07801","0780186","ﾎｯｶｲﾄﾞｳ","ｱｻﾋｶﾜｼ","ｶﾑｲﾁｮｳﾆｼｵｶ(8-22ﾊﾞﾝﾁ)","北海道","旭川市","神居町西丘（８−２２番地）",1,0,0,0,0,},
    q{01207,"08023","0802333","ﾎｯｶｲﾄﾞｳ","ｵﾋﾞﾋﾛｼ","ﾋﾞｴｲﾁｮｳ(ﾆｼ5-8ｾﾝ79-110ﾊﾞﾝﾁ)","北海道","帯広市","美栄町（西５〜８線７９〜１１０番地）",1,0,0,0,0,0},
    q{01210,"06831","0683161","ﾎｯｶｲﾄﾞｳ","ｲﾜﾐｻﾞﾜｼ","ｸﾘｻﾜﾁｮｳﾐﾔﾑﾗ(248､339､726､780､800､806ﾊﾞﾝﾁ)","北海道","岩見沢市","栗沢町宮村（２４８、３３９、７２６、７８０、８００、８０６番地）",1,0,0,0,0,0};

do {
    my $row = $parser->fetch_obj;
    is($row->town, '常盤');
    is($row->town_kana, 'トキワ');
    ok($row->has_subtown);
    is($row->subtown->[0], '1〜131番地');
    is($row->subtown_kana->[0], '1-131バンチ');
};
do {
    my $row = $parser->fetch_obj;
    is($row->town, '藤野');
    is($row->town_kana, 'フジノ');
    ok($row->has_subtown);
    is($row->subtown->[0], '400');
    is($row->subtown_kana->[0], '400');
    is($row->subtown->[1], '400-2番地');
    is($row->subtown_kana->[1], '400-2バンチ');
};
do {
    my $row = $parser->fetch_obj;
    is($row->town, '真駒内');
    is($row->town_kana, 'マコマナイ');
    ok($row->has_subtown);
    is($row->subtown->[0], '17番地');
    is($row->subtown_kana->[0], '17バンチ');
};
do {
    my $row = $parser->fetch_obj;
    is($row->town, '神居町西丘');
    is($row->town_kana, 'カムイチョウニシオカ');
    ok($row->has_subtown);
    is($row->subtown->[0], '8-22番地');
    is($row->subtown_kana->[0], '8-22バンチ');
};
do {
    my $row = $parser->fetch_obj;
    is($row->town, '美栄町');
    is($row->town_kana, 'ビエイチョウ');
    ok($row->has_subtown);
    is($row->subtown->[0], '西5〜8線79〜110番地');
    is($row->subtown_kana->[0], 'ニシ5-8セン79-110バンチ');
};
do {
    my $row = $parser->fetch_obj;
    is($row->town, '栗沢町宮村');
    is($row->town_kana, 'クリサワチョウミヤムラ');
    ok($row->has_subtown);
    is($row->subtown->[0], '248');
    is($row->subtown_kana->[0], '248');
    is($row->subtown->[1], '339');
    is($row->subtown_kana->[1], '339');
    is($row->subtown->[2], '726');
    is($row->subtown_kana->[2], '726');
    is($row->subtown->[3], '780');
    is($row->subtown_kana->[3], '780');
    is($row->subtown->[4], '800');
    is($row->subtown_kana->[4], '800');
    is($row->subtown->[5], '806番地');
    is($row->subtown_kana->[5], '806バンチ');
};

done_testing;
