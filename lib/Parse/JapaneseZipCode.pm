package Parse::JapaneseZipCode;
use strict;
use warnings;
use utf8;
our $VERSION = '0.01';

use Parse::JapaneseZipCode::Row;

sub new {
    my($class, %opts) = @_;

    my $self = bless {
        format => 'ken',
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
    my @names = Parse::JapaneseZipCode::Row->columns;
    my %columns;
    @columns{@names} = @{ $row };

    Parse::JapaneseZipCode::Row->new(
        build_town      => $self->{current_build_town},
        build_town_kana => $self->{current_build_town_kana},
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
        while (1) {
            my $tmp = $self->_get_line;
            return unless $tmp;
            $row->[5] .= $tmp->[5];
            $row->[8] .= $tmp->[8];
            last if $row->[8] =~ /\）$/;
        }
    }

    my $town = $row->[8];

    if ($town =~ /^(.+)（次のビルを除く）$/) {
        $self->{current_build_town} = $1;
        ($self->{current_build_town_kana}) = $row->[5] =~ /^(.+)\(/;
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

Parse::JapaneseZipCode - ZipCode Parser for 日本郵政

=head1 SYNOPSIS

    use Parse::JapaneseZipCode;

    my $parser = Parse::JapaneseZipCode->new( file => 'KEN_ALL.csv' );
    while (my $obj = $parser->fetch_obj) {
        my @list = ($obj->zip, $obj->pref, $obj->city, $obj->town);
        # TODO: my @list = map { $_ ? $_ : () } ($obj->zip, $obj->pref, $obj->district, $obj->city, $obj->ward, $obj->town);
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

Parse::JapaneseZipCode は、日本郵政が提供している郵便番号ファイルを良い感じにパースしてくれるパーサです。

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo {at} shibuya {dot} plE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
