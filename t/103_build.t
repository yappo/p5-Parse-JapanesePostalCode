use strict;
use warnings;
use utf8;
use Test::More;

use Parse::JapaneseZipCode;

my $data = join "\r\n",
    q{13113,"150  ","1500013","ﾄｳｷｮｳﾄ","ｼﾌﾞﾔｸ","ｴﾋﾞｽ(ﾂｷﾞﾉﾋﾞﾙｦﾉｿﾞｸ)","東京都","渋谷区","恵比寿（次のビルを除く）",0,0,1,0,0,0},
    q{13113,"150  ","1506090","ﾄｳｷｮｳﾄ","ｼﾌﾞﾔｸ","ｴﾋﾞｽｴﾋﾞｽｶﾞｰﾃﾞﾝﾌﾟﾚｲｽ(ﾁｶｲ･ｶｲｿｳﾌﾒｲ)","東京都","渋谷区","恵比寿恵比寿ガーデンプレイス（地階・階層不明）",0,0,0,0,0,0},
    q{13113,"150  ","1506001","ﾄｳｷｮｳﾄ","ｼﾌﾞﾔｸ","ｴﾋﾞｽｴﾋﾞｽｶﾞｰﾃﾞﾝﾌﾟﾚｲｽ(1ｶｲ)","東京都","渋谷区","恵比寿恵比寿ガーデンプレイス（１階）",0,0,0,0,0,0},
    q{13113,"150  ","1500021","ﾄｳｷｮｳﾄ","ｼﾌﾞﾔｸ","ｴﾋﾞｽﾆｼ","東京都","渋谷区","恵比寿西",0,0,1,0,0,0},
    q{23105,"450  ","4506051","ｱｲﾁｹﾝ","ﾅｺﾞﾔｼﾅｶﾑﾗｸ","ﾒｲｴｷｼﾞｪｲｱｰﾙｾﾝﾄﾗﾙﾀﾜｰｽﾞ(51ｶｲ)","愛知県","名古屋市中村区","名駅ＪＲセントラルタワーズ（５１階）",0,0,0,0,0,0},
    q{23105,"450  ","4506290","ｱｲﾁｹﾝ","ﾅｺﾞﾔｼﾅｶﾑﾗｸ","ﾒｲｴｷﾐｯﾄﾞﾗﾝﾄﾞｽｸｴｱ(ｺｳｿｳﾄｳ)(ﾁｶｲ･ｶｲｿｳﾌﾒｲ)","愛知県","名古屋市中村区","名駅ミッドランドスクエア（高層棟）（地階・階層不明）",0,0,0,0,0,0},
    q{23105,"450  ","4506201","ｱｲﾁｹﾝ","ﾅｺﾞﾔｼﾅｶﾑﾗｸ","ﾒｲｴｷﾐｯﾄﾞﾗﾝﾄﾞｽｸｴｱ(ｺｳｿｳﾄｳ)(1ｶｲ)","愛知県","名古屋市中村区","名駅ミッドランドスクエア（高層棟）（１階）",0,0,0,0,0,0};
    
$data .= "\r\n";
open my $fh, '<:utf8', \$data;

my $parser = Parse::JapaneseZipCode->new( fh => $fh );

subtest 'other' => sub {
    my $row = $parser->fetch_obj;
    is($row->zip, '1500013');
    is($row->town, '恵比寿');
    is($row->town_kana, 'エビス');
    is($row->build, undef);
    is($row->build_kana, undef);
    is($row->floor, undef);
};

subtest 'none' => sub {
    my $row = $parser->fetch_obj;
    is($row->zip, '1506090');
    is($row->town, '恵比寿');
    is($row->town_kana, 'エビス');
    is($row->build, '恵比寿ガーデンプレイス');
    is($row->build_kana, 'エビスガーデンプレイス');
    is($row->floor, undef);
};

subtest 'one' => sub {
    my $row = $parser->fetch_obj;
    is($row->zip, '1506001');
    is($row->town, '恵比寿');
    is($row->town_kana, 'エビス');
    is($row->build, '恵比寿ガーデンプレイス');
    is($row->build_kana, 'エビスガーデンプレイス');
    is($row->floor, '1');
};

subtest 'end' => sub {
    my $row = $parser->fetch_obj;
    is($row->zip, '1500021');
    is($row->town, '恵比寿西');
    is($row->town_kana, 'エビスニシ');
    is($row->build, undef);
    is($row->build_kana, undef);
    is($row->floor, undef);
};

subtest 'meieki 1' => sub {
    my $row = $parser->fetch_obj;
    is($row->zip, '4506051');
    is($row->town, '');
    is($row->town_kana, '');
    is($row->build, '名駅ＪＲセントラルタワーズ');
    is($row->build_kana, 'メイエキジェイアールセントラルタワーズ');
    is($row->floor, '51');
};

subtest 'meieki 2' => sub {
    my $row = $parser->fetch_obj;
    is($row->zip, '4506290');
    is($row->town, '');
    is($row->town_kana, '');
    is($row->build, '名駅ミッドランドスクエア');
    is($row->build_kana, 'メイエキミッドランドスクエア');
    is($row->floor, undef);
};

subtest 'meieki 3' => sub {
    my $row = $parser->fetch_obj;
    is($row->zip, '4506201');
    is($row->town, '');
    is($row->town_kana, '');
    is($row->build, '名駅ミッドランドスクエア');
    is($row->build_kana, 'メイエキミッドランドスクエア');
    is($row->floor, '1');
};

done_testing;
