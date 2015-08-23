package Parse::JapanesePostalCode::Row;
use strict;
use warnings;
use utf8;

use Lingua::JA::Regular::Unicode qw/ katakana_h2z /;

sub alnum_z2h {
    my $str = shift;
    $str = Lingua::JA::Regular::Unicode::alnum_z2h($str);
    $str =~ tr/~−/〜-/;
    $str;
}

my @COLUMNS = qw/
    region_id old_zip zip
    pref_kana region_kana town_kana pref region town
    is_multi_zip has_koaza_banchi has_chome is_multi_town
    update_status update_reason
/;

my @METHODS = (@COLUMNS, qw/
    district district_kana city city_kana ward ward_kana
    subtown_kana subtown
    build build_kana floor
/);

for my $name (@METHODS) {
    my $sub = sub { $_[0]->{columns}{$name} };
    no strict 'refs';
    *{$name} = $sub;
}

sub columns { @COLUMNS }

sub has_subtown { !! $_[0]->subtown }

sub new {
    my($class, %opts) = @_;

    my $columns = {};
    for my $column (@COLUMNS) {
        $columns->{$column} = delete $opts{$column} if defined $opts{$column};
    }

    my $self = bless {
        katakana_h2z    => 1,
        alnum_z2h       => 1,
        build_town      => '',
        build_town_kana => '',
        %opts,
        columns      => $columns,
    }, $class;

    $self->fix_region;
    $self->fix_town;
    $self->fix_build;
    $self->fix_subtown unless $self->build;
    $self->fix_kana_alnum;

    $self;
}

sub fix_region {
    my $self = shift;
    my $columns = $self->{columns};

    $columns->{district}      = undef;
    $columns->{district_kana} = undef;
    $columns->{city}          = undef;
    $columns->{city_kana}     = undef;
    $columns->{ward}          = undef;
    $columns->{ward_kana}     = undef;

    # district
    my($district, $town_village) = $self->region =~ /^(.+?郡)(.+[町村])$/;
    if ($district && $town_village) {
        my($district_kana, $town_village_kana) = $self->region_kana =~ /^((?:ｷﾀｸﾞﾝﾏ|.+?)ｸﾞﾝ)(.+)$/;

        $columns->{district}      = $district;
        $columns->{district_kana} = $district_kana;
        $columns->{city}          = $town_village;
        $columns->{city_kana}     = $town_village_kana;
    } else {
        my($city, $ward) = $self->region =~ /^(.+市)(.+区)$/;
        if ($city && $ward) {
            my($city_kana, $ward_kana) = $self->region_kana =~ /^((?:ﾋﾛｼﾏ|ｷﾀｷｭｳｼｭｳ|.+?)ｼ)(.+)$/;

            $columns->{city}      = $city;
            $columns->{city_kana} = $city_kana;
            $columns->{ward}      = $ward;
            $columns->{ward_kana} = $ward_kana;
        } elsif ($self->region =~ /区$/) {
            $columns->{ward}      = $self->region;
            $columns->{ward_kana} = $self->region_kana;
        } else {
            $columns->{city}      = $self->region;
            $columns->{city_kana} = $self->region_kana;
        }
    }
}

sub fix_town {
    my $self = shift;
    my $columns = $self->{columns};
    if ($columns->{town} eq '以下に掲載がない場合') {
        $columns->{town_kana} = undef;
        $columns->{town}      = undef;
    } elsif ($columns->{town} =~ /^(.+)の次に番地がくる場合/) { 
        my $name = $1;
        if ($columns->{city} eq $name || $columns->{city} =~ /郡\Q$name\E$/) {
            $columns->{town_kana} = undef;
            $columns->{town}      = undef;
        }
    } elsif ($columns->{town} =~ s/（その他）$//) {
        $columns->{town_kana} =~ s/\(ｿﾉﾀ\)$//;
    } elsif ($columns->{town} =~ /^(.+[町村])一円$/) {
        my $name = $1;
        if ($columns->{city} eq $name) {
            $columns->{town_kana} = undef;
            $columns->{town}      = undef;
        }
    }

    $columns->{town} =~ s/[〜～]/〜/g if $columns->{town};
}

sub fix_subtown {
    my $self = shift;
    my $columns = $self->{columns};
    return unless $columns->{town};

    my @subtown;
    my @subtown_kana;

    # chome
    if ($columns->{town} =~ s/（([\d〜、]+)丁目）$//) {
        my $num = alnum_z2h($1);

        my @nums = map {
            if (/^(\d+)〜(\d+)$/) {
                ($1..$2);
            } else {
                $_
            }
        } map { alnum_z2h($_) } split /、/, $1;

        @subtown      = map { $_ . '丁目' } @nums;
        @subtown_kana = map { $_ . 'チョウメ' } @nums;

        $columns->{town_kana} =~ s/\([\d\-､]+ﾁｮｳﾒ\)$//;
    }
    # chiwari
    elsif ($columns->{town} =~ /^[^\（]+地割/) {
        my($prefix, $koaza)           = $columns->{town}      =~ /^(.+\d+地割)(?:（(.+)）)?$/;
        my($prefix_kana, $koaza_kana) = $columns->{town_kana} =~ /^(.+\d+ﾁﾜﾘ)(?:\((.+)\))?$/;

        my($aza, $chiwari)           = $prefix      =~ /^(.+?)第?(\d+地割.*)$/;
        my($aza_kana, $chiwari_kana) = $prefix_kana =~ /^(.+?)(?:ﾀﾞｲ)?(\d+ﾁﾜﾘ.*)$/;

        if ($chiwari =~ /〜/) {
            my @tmp = map {
                if (/\d+地割$/) {
                    my $str = $_;
                    $str =~ s/^\Q$aza\E//;
                    $str =~ s/^第//;
                    "第$str";
                } else {
                    $_;
                }
            } split /〜/, $chiwari;
            $chiwari = join '〜', @tmp;
        }
        if ($chiwari_kana =~ /-/) {
            my @tmp = map {
                if (/\d+ﾁﾜﾘ$/) {
                    my $str = $_;
                    $str =~ s/^\Q$aza_kana\E//;
                    $str =~ s/^ﾀﾞｲ//;
                    "ﾀﾞｲ$str";
                } else {
                    $_;
                }
            } split /-/, $chiwari_kana;
            $chiwari_kana = join '-', @tmp;
        }

        @subtown = map {
            if (/\d+地割$/) {
                my $str = $_;
                $str =~ s/^\Q$aza\E//;
                $str =~ s/^第//;
                "第$str";
            } else {
                $_;
            }
        } split /、/, $chiwari;
        @subtown_kana = map {
            if (/\d+ﾁﾜﾘ$/) {
                my $str = $_;
                $str =~ s/^\Q$aza_kana\E//;
                $str =~ s/^ﾀﾞｲ//;
                "ﾀﾞｲ$str";
            } else {
                $_;
            }
        } split /､/, $chiwari_kana;

        if ($koaza) {
            @subtown = map {
                my $str = $_;
                map {
                    "$str $_";
                } split /、/, $koaza;
            } @subtown;
        }
        if ($koaza_kana) {
            @subtown_kana = map {
                my $str = $_;
                map {
                    "$str $_";
                } split /､/, $koaza_kana;
            } @subtown_kana;
        }

        $columns->{town}      = $aza;
        $columns->{town_kana} = $aza_kana;
    }
    # other
    elsif ($columns->{town} =~ s/（(.+?)）$//) {
        my $town = $1;
        $town =~ s{「([^\」]+)」}{
            my $str = $1;
            $str =~ s/、/_____COMMNA_____/g;
            "「${str}」";
        }ge;
        @subtown = map {
            my $str = $_;
            $str =~ s/_____COMMNA_____/、/g;
            $str;
        } split /、/, $town;
        if ($columns->{town_kana} =~ s/\((.+?)\)$//) {
            my $kana = $1;
            $kana =~ s{<([^>]+)>}{
                my $str = $1;
                $str =~ s/､/_____COMMNA_____/g;
                "<${str}>";
            }ge;
            @subtown_kana = map {
                my $str = $_;
                $str =~ s/_____COMMNA_____/,/g;
                $str;
            } split /､/, $kana;
        }
    }

    if (@subtown) {
        $columns->{subtown}      = \@subtown;
        $columns->{subtown_kana} = \@subtown_kana;
    }
}

sub fix_build {
    my $self = shift;
    my $columns = $self->{columns};

    unless ($self->{build_town}) {
        unless ($columns->{town} && $columns->{town} =~ /（.+?階.*?）$/) {
            return;
        }
    }

    my $build_town      = $self->{build_town};
    my $build_town_kana = $self->{build_town_kana};

    $columns->{town}      =~ s/（高層棟）//;
    $columns->{town_kana} =~ s/\(ｺｳｿｳﾄｳ\)//;
    if ($columns->{town} =~ s/（次のビルを除く）$//) {
        $columns->{town_kana} =~ s/\(ﾂｷﾞﾉﾋﾞﾙｦﾉｿﾞｸ\)$//;
    } elsif ($columns->{town} =~ /^\Q$build_town\E(.+)（(.+)）$/) {
        my $floor = $2;
        $columns->{build} = $1;
        if ($floor =~ /(\d+)階/) {
            $columns->{floor} = alnum_z2h($1);
        }

        $columns->{town_kana} =~ /^\Q$build_town_kana\E(.+)\(.+$/;
        $columns->{build_kana} = $1;

        $columns->{town}      = $build_town;
        $columns->{town_kana} = $build_town_kana;
    }
}

sub fix_kana_alnum {
    my $self = shift;
    return unless$self->{katakana_h2z} || $self->{alnum_z2h};
    for my $name (qw/ pref_kana region_kana district_kana city_kana ward_kana town_kana build_kana pref region district city ward town build /) {
        next unless defined $self->{columns}{$name};
        $self->{columns}{$name} = katakana_h2z($self->{columns}{$name}) if $self->{katakana_h2z};
        $self->{columns}{$name} = alnum_z2h($self->{columns}{$name})    if $self->{alnum_z2h};
    }
    if ($self->has_subtown) {
        for my $i (0..(scalar(@{ $self->subtown }) - 1)) {
            $self->subtown->[$i]      = katakana_h2z($self->subtown->[$i]) if $self->{katakana_h2z};
            $self->subtown->[$i]      = alnum_z2h($self->subtown->[$i])    if $self->{alnum_z2h};
        }
        for my $i (0..(scalar(@{ $self->subtown_kana }) - 1)) {
            $self->subtown_kana->[$i] = katakana_h2z($self->subtown_kana->[$i]) if $self->{katakana_h2z};
            $self->subtown_kana->[$i] = alnum_z2h($self->subtown_kana->[$i])    if $self->{alnum_z2h};
        }
    }
}

1;
__END__

=encoding utf8

=head1 NAME

Parse::JapanesePostalCode::Row - Object of Japanese PostalCode

=head1 METHODS

=head2 new

instance method.

=head2 region_id

全国地方公共団体コード(JIS X0401、X0402) を返します。

=head2 old_zip

(旧)郵便番号(5桁) を返します。

=head2 zip

郵便番号(7桁) を返します。

=head2 pref

都道府県名 を返します。

=head2 region

市区町村名 を返します。町村の場合には郡を含み、政令指定都市の場合には区を含みます。

=head2 district

region から、郡名を抜き出した物を返します。なければ undef が返ります。

=head2 city

region から、市名を抜き出した物を返します。なければ undef が返ります。

=head2 ward

region から、区名を抜き出した物を返します。なければ undef が返ります。

=head2 town

町域名 を返します。小字、丁目、番地，号、ビル名等は含まれません。基本的に大字と同等の町域名が入ります。
実質町域を指定していない物では undef が返ります。

=head2 build

ビル名が入ります。なければ undef が返ります。

=head2 floor

ビルの階が入ります。地階、不明階やビルでない場合には undef が返ります。

=head2 has_subtown

小字、丁目、番地，号がある場合には真が返ります。

=head2 subtown

小字、丁目、番地，号等が ARRAY ref で返ります。

=head2 pref

都道府県名 を返します。

=head2 region_kana

カタカナが返ります。

=head2 district_kana

カタカナが返ります。

=head2 city_kana

カタカナが返ります。

=head2 ward_kana

カタカナが返ります。

=head2 town_kana

カタカナが返ります。

=head2 build_kana

カタカナが返ります。

=head2 subtown_kana

カタカナが返ります。

=head2 is_multi_zip

一町域が二以上の郵便番号で表される場合の表示 が返ります。

=head2 has_koaza_banchi

小字毎に番地が起番されている町域の表示 が返ります。

=head2 has_chome

丁目を有する町域の場合の表示 が返ります。

=head2 is_multi_town

一つの郵便番号で二以上の町域を表す場合の表示 が返ります。

=head2 update_status

更新の表示 が返ります。

=head2 update_reason

変更理由 が返ります。

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo {at} shibuya {dot} plE<gt>

=head1 SEE ALSO

L<Parse::JapanesePostalCode>,
L<http://www.post.japanpost.jp/zipcode/download.html>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
