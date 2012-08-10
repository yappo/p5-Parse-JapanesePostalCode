use strict;
use warnings;
use parent 'Exporter';

our @EXPORT = qw/ make_parser /;

use Parse::JapaneseZipCode;

sub make_parser {
    my $data = join "\r\n", @_;
    $data .= "\r\n";
    open my $fh, '<:utf8', \$data;
    Parse::JapaneseZipCode->new( fh => $fh );
}

1;

