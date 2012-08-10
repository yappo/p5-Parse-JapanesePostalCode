use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

my $parser = make_parser
    q{23105,"450  ","4500002","ｱｲﾁｹﾝ","ﾅｺﾞﾔｼﾅｶﾑﾗｸ","ﾒｲｴｷ(ｿﾉﾀ)","愛知県","名古屋市中村区","名駅（その他）",1,0,1,0,0,0};

subtest 'other' => sub {
    my $row = $parser->fetch_obj;
    is($row->town, '名駅');
    is($row->town_kana, 'メイエキ');
};

done_testing;
