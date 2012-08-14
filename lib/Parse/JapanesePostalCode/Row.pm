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
        $columns->{town_kana} =~ s/\((.+?)\)$//;
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

    $columns->{subtown}      = \@subtown      if @subtown;
    $columns->{subtown_kana} = \@subtown_kana if @subtown_kana;
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

Parse::JapanesePostalCode::Row -

=cut
