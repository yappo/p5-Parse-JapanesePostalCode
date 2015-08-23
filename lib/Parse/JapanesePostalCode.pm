package Parse::JapanesePostalCode;
use strict;
use warnings;
use utf8;
our $VERSION = '0.02';

use Parse::JapanesePostalCode::Row;

sub new {
    my($class, %opts) = @_;

    my $self = bless {
        format => 'ken',
        katakana_h2z => 1,
        alnum_z2h    => 1,
        %opts,
        current_build_town      => '',
        current_build_town_kana => '',
    }, $class;

    if ( ! $self->{fh} && $self->{file} && -f $self->{file}) {
        open $self->{fh}, '<:encoding(cp932)', $self->{file};
    }

    $self;
}

sub fetch_obj {
    my($self, ) = @_;

    my $row = $self->get_line;
    return unless $row;
    my @names = Parse::JapanesePostalCode::Row->columns;
    my %columns;
    @columns{@names} = @{ $row };

    Parse::JapanesePostalCode::Row->new(
        build_town      => $self->{current_build_town},
        build_town_kana => $self->{current_build_town_kana},
        katakana_h2z    => $self->{katakana_h2z},
        alnum_z2h       => $self->{alnum_z2h},
        %columns,
    );
}

sub _get_line {
    my($self, ) = @_;

    my $fh = $self->{fh};
    my $line = <$fh>;
    return unless $line;
    $line =~ s/\r\n$//;

    # easy csv parser for KEN_ALL.csv
    my @row = map {
        my $data = $_;
        $data =~ s/^"//;
        $data =~ s/"$//;
        $data;
    } split ',', $line;

    \@row;
}

sub get_line {
    my($self, ) = @_;

    my $row = $self->_get_line;
    return unless $row;
    if ($row->[8] =~ /（.+[^）]$/) {
        my $past_town_kana = $row->[5];
        while (1) {
            my $tmp = $self->_get_line;
            return unless $tmp;
            $row->[5] .= $tmp->[5] unless $past_town_kana eq $tmp->[5];
            $row->[8] .= $tmp->[8];
            last if $row->[8] =~ /\）$/;
            $past_town_kana = $tmp->[5];
        }
    }

    my $town = $row->[8];

    if ($town =~ /^(.+)（次のビルを除く）$/) {
        $self->{current_build_town} = $1;
        ($self->{current_build_town_kana}) = $row->[5] =~ /^(.+)\(/;
    } elsif ($row->[2] eq '4530002' && $town =~ /^名駅\（/) {
        $self->{current_build_town}      = '名駅';
        $self->{current_build_town_kana} = 'ﾒｲｴｷ';
    } else {
        my $current_build_town = $self->{current_build_town};
        unless ($town =~ /^$current_build_town.+（.+階.*）$/) {
            $self->{current_build_town}      = '';
            $self->{current_build_town_kana} = '';
        }
    }

    $row;
}

1;
__END__

=encoding utf8

=head1 NAME

Parse::JapanesePostalCode - PostalCode Parser for 日本郵政

=head1 SYNOPSIS

    use Parse::JapanesePostalCode;

    my $parser = Parse::JapanesePostalCode->new( file => 'KEN_ALL.csv' );
    while (my $obj = $parser->fetch_obj) {
        my @list = map { $_ ? $_ : () } ($obj->zip, $obj->pref, $obj->district, $obj->city, $obj->ward, $obj->town);
        if ($obj->has_subtown) {
            push @list, join '/', @{ $obj->subtown };
        }
        if ($obj->build) {
            my $str = $obj->build;
            $str .= $obj->floor . 'F' if $obj->floor;
            push @list, $str;
        }
    }

=head1 DESCRIPTION

Parse::JapanesePostalCode is a feel good parser to parse to Postal Code files that are provided by Japan Post.

Parse::JapanesePostalCode は、日本郵政が提供している郵便番号ファイルを良い感じにパースしてくれるパーサです。

=head1 METHODS

=head2 new

create to parser instance.

read from file path.

    my $parser = Parse::JapanesePostalCode->new(
        file => 'foo/bar/KEN_ALL.csv',
    );

read from file handle.

    my $parser = Parse::JapanesePostalCode->new(
        fh => $ken_all_fh,
    );

ignore katakana_h2z.

    my $parser = Parse::JapanesePostalCode->new(
        file => 'foo/bar/KEN_ALL.csv',
        katakana_h2z => 0,
    );

ignore alnum_z2h.

    my $parser = Parse::JapanesePostalCode->new(
        file => 'foo/bar/KEN_ALL.csv',
        alnum_z2h => 0,
    );

=head2 get_line

get one line from KEN_ALL.csv.

    while (my $line = $parser->get_line) {
      say $line;
    }

1行読み込みます。もし

    07543,"97906","9790622","ﾌｸｼﾏｹﾝ","ﾌﾀﾊﾞｸﾞﾝﾄﾐｵｶﾏﾁ","ｹｶﾞﾔ(ﾏｴｶﾜﾊﾗ232-244､311､312､337-862ﾊﾞﾝﾁ","福島県","双葉郡富岡町","毛萱（前川原２３２〜２４４、３１１、３１２、３３７〜８６２番地",1,1,0,0,0,0
    07543,"97906","9790622","ﾌｸｼﾏｹﾝ","ﾌﾀﾊﾞｸﾞﾝﾄﾐｵｶﾏﾁ","ﾄｳｷｮｳﾃﾞﾝﾘｮｸﾌｸｼﾏﾀﾞｲ2ｹﾞﾝｼﾘｮｸﾊﾂﾃﾞﾝｼｮｺｳﾅｲ)","福島県","双葉郡富岡町","〔東京電力福島第二原子力発電所構内〕）",1,1,0,0,0,0

のように複数行に分割されていたら、良い感じに行をマージした結果を返します。

=head2 fetch_obj

get one line object from KEN_ALL.csv.

    while (my $obj = $parser->fetch_obj) {
      say $obj->zip;
    }

get_line で取得した行を、 L<Parse::JapanesePostalCode::Row> でオブジェクト化したオブジェクトを返します。

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo {at} shibuya {dot} plE<gt>

=head1 SEE ALSO

L<Parse::JapanesePostalCode::Row>,
L<http://www.post.japanpost.jp/zipcode/download.html>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
