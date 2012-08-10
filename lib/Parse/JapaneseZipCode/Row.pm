package Parse::JapaneseZipCode::Row;
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
    pref_kana city_kana town_kana pref city town
    is_multi_zip has_koaza_banchi has_chome is_multi_town
    update_status update_reason
/;

my @METHODS = (@COLUMNS, qw/
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

    $self->fix_town;
    $self->fix_subtown;
    $self->fix_build;
    $self->fix_kana_alnum;

    $self;
}

sub fix_town {
    my $self = shift;
    my $columns = $self->{columns};
    if ($columns->{town} eq '以下に掲載がない場合') {
        $columns->{town_kana} = undef;
        $columns->{town}      = undef;
    } elsif ($columns->{town} =~ s/（その他）$//) {
        $columns->{town_kana} =~ s/\(ｿﾉﾀ\)$//;
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
    # banchi
    elsif ($columns->{town} =~ s/（(.+?番地)）$//) {
        @subtown = map { alnum_z2h($_) } split /、/, $1;
        $columns->{town_kana} =~ s/\((.+?ﾊﾞﾝﾁ)\)$//;
        @subtown_kana = map { alnum_z2h($_) } split /､/, $1;
    }
    # chiwari
    elsif ($columns->{town} =~ /地割/) {
        my($prefix, $koaza)           = $columns->{town}      =~ /^(.+\d+地割)(?:（(.+)）)?$/;
        my($prefix_kana, $koaza_kana) = $columns->{town_kana} =~ /^(.+\d+ﾁﾜﾘ)(?:\((.+)\))?$/;

        my($aza, $chiwari)           = $prefix      =~ /^(.+?)第?(\d+地割.*)$/;
        my($aza_kana, $chiwari_kana) = $prefix_kana =~ /^(.+?)(?:ﾀﾞｲ)?(\d+ﾁﾜﾘ.*)$/;

        if ($chiwari =~ /〜/) {
            my @tmp = map {
                if (/\d+地割$/) {
                    my $str = $_;
                    $str =~ s/^$aza//;
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
                    $str =~ s/^$aza_kana//;
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
                $str =~ s/^$aza//;
                $str =~ s/^第//;
                "第$str";
            } else {
                $_;
            }
        } split /、/, $chiwari;
        @subtown_kana = map {
            if (/\d+ﾁﾜﾘ$/) {
                my $str = $_;
                $str =~ s/^$aza_kana//;
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
    } elsif ($columns->{town} =~ /^$build_town(.+)（(.+)）$/) {
        my $floor = $2;
        $columns->{build} = $1;
        if ($floor =~ /(\d+)階/) {
            $columns->{floor} = alnum_z2h($1);
        }

        $columns->{town_kana} =~ /^$build_town_kana(.+)\(.+$/;
        $columns->{build_kana} = $1;

        $columns->{town}      = $build_town;
        $columns->{town_kana} = $build_town_kana;
    }
}

sub fix_kana_alnum {
    my $self = shift;
    return unless$self->{katakana_h2z} || $self->{alnum_z2h};
    for my $name (qw/ pref_kana city_kana town_kana build_kana pref city town build /) {
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

Parse::JapaneseZipCode::Row -

=cut
