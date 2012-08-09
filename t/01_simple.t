use strict;
use warnings;
use utf8;
use Test::More;

use File::Temp 'tempfile';

use Parse::JapaneseZipCode;

my($fh, $filename) = tempfile( UNLINK => 1 );
close $fh;
open $fh, '>:encoding(cp932)', $filename;
print $fh q{01101,"064  ","0640941","ﾎｯｶｲﾄﾞｳ","ｻｯﾎﾟﾛｼﾁｭｳｵｳｸ","ｱｻﾋｶﾞｵｶ","北海道","札幌市中央区","旭ケ丘",0,0,1,0,0,0};
print $fh "\r\n";
close $fh;

my $parser = Parse::JapaneseZipCode->new(
    file => $filename,
);

my $row = $parser->get_line;
is(scalar(@{ $row }), 15);

$row = $parser->get_line;
is($row, undef);


done_testing;
