use strict;
use warnings;
use utf8;
use Test::More;

use File::Temp 'tempfile';

use Parse::JapanesePostalCode;

my($fh, $filename) = tempfile( UNLINK => 1 );
close $fh;
open $fh, '>:encoding(cp932)', $filename;
print $fh q{23105,"450  ","4506001","ｱｲﾁｹﾝ","ﾅｺﾞﾔｼﾅｶﾑﾗｸ","ﾒｲｴｷｼﾞｪｲｱｰﾙｾﾝﾄﾗﾙﾀﾜｰｽﾞ(1ｶｲ)","愛知県","名古屋市中村区","名駅ＪＲセントラルタワーズ（１階）",0,0,0,0,0,0};
print $fh "\r\n";
close $fh;

subtest 'katakana_h2z alnum_z2h' => sub {
    my $parser = Parse::JapanesePostalCode->new(
        file         => $filename,
        katakana_h2z => 0,
        alnum_z2h    => 0,
    );

    my $row = $parser->fetch_obj;
    is($row->build, '名駅ＪＲセントラルタワーズ');
    is($row->build_kana, 'ﾒｲｴｷｼﾞｪｲｱｰﾙｾﾝﾄﾗﾙﾀﾜｰｽﾞ');
};

subtest 'katakana_h2z' => sub {
    my $parser = Parse::JapanesePostalCode->new(
        file         => $filename,
        katakana_h2z => 0,
        alnum_z2h    => 1,
    );

    my $row = $parser->fetch_obj;
    is($row->build, '名駅JRセントラルタワーズ');
    is($row->build_kana, 'ﾒｲｴｷｼﾞｪｲｱｰﾙｾﾝﾄﾗﾙﾀﾜｰｽﾞ');
};

subtest 'alnum_z2h' => sub {
    my $parser = Parse::JapanesePostalCode->new(
        file         => $filename,
        katakana_h2z => 1,
        alnum_z2h    => 0,
    );

    my $row = $parser->fetch_obj;
    is($row->build, '名駅ＪＲセントラルタワーズ');
    is($row->build_kana, 'メイエキジェイアールセントラルタワーズ');
};

done_testing;
