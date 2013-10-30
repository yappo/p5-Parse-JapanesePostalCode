use strict;
use warnings;
use parent 'Exporter';

our @EXPORT = qw/ make_parser /;

use Parse::JapanesePostalCode;
use Encode;

sub make_parser {
    my $data = join "\r\n", @_;
    $data .= "\r\n";
    $data = Encode::encode_utf8($data);
    open my $fh, '<:utf8', \$data;
    Parse::JapanesePostalCode->new( fh => $fh );
}

1;

