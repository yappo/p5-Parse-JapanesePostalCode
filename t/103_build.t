use strict;
use warnings;
use utf8;
use Test::More;

use Parse::JapaneseZipCode;

my $data = join "\r\n",
    q{13113,"150  ","1500013","ﾄｳｷｮｳﾄ","ｼﾌﾞﾔｸ","ｴﾋﾞｽ(ﾂｷﾞﾉﾋﾞﾙｦﾉｿﾞｸ)","東京都","渋谷区","恵比寿（次のビルを除く）",0,0,1,0,0,0},
    q{13113,"150  ","1506090","ﾄｳｷｮｳﾄ","ｼﾌﾞﾔｸ","ｴﾋﾞｽｴﾋﾞｽｶﾞｰﾃﾞﾝﾌﾟﾚｲｽ(ﾁｶｲ･ｶｲｿｳﾌﾒｲ)","東京都","渋谷区","恵比寿恵比寿ガーデンプレイス（地階・階層不明）",0,0,0,0,0,0},
    q{13113,"150  ","1506001","ﾄｳｷｮｳﾄ","ｼﾌﾞﾔｸ","ｴﾋﾞｽｴﾋﾞｽｶﾞｰﾃﾞﾝﾌﾟﾚｲｽ(1ｶｲ)","東京都","渋谷区","恵比寿恵比寿ガーデンプレイス（１階）",0,0,0,0,0,0},
    q{13113,"150  ","1500021","ﾄｳｷｮｳﾄ","ｼﾌﾞﾔｸ","ｴﾋﾞｽﾆｼ","東京都","渋谷区","恵比寿西",0,0,1,0,0,0};
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
done_testing;exit;

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

done_testing;
