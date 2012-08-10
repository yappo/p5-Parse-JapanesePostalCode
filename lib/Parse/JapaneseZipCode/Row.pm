package Parse::JapaneseZipCode::Row;
use strict;
use warnings;
use utf8;

use Lingua::JA::Regular::Unicode qw/ alnum_z2h katakana_h2z /;

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

sub get_subtown_list {
    my $self = shift;
    return unless $self->subtown;
    ref($self->subtown) eq 'ARRAY' ? @{ $self->subtown } : ( $self->subtown );
}

sub get_subtown_kana_list {
    my $self = shift;
    return unless $self->subtown_kana;
    ref($self->subtown_kana) eq 'ARRAY' ? @{ $self->subtown_kana } : ( $self->subtown_kana );
}

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
}

sub fix_subtown {
    my $self = shift;
    my $columns = $self->{columns};
    return unless $columns->{town};

    my @subtown;
    my @subtown_kana;

    # chome
    if ($columns->{town} =~ s/（(\d+)丁目）$//) {
        my $num = alnum_z2h($1);
        @subtown      = ("${num}丁目");;
        @subtown_kana = ("${num}チョウメ");
        $columns->{town_kana} =~ s/\(\d+ﾁｮｳﾒ\)$//;
    } elsif ($columns->{town} =~ s/（(\d+(?:、\d+))丁目）$//) {
        my @nums = map { alnum_z2h($_) } split /、/, $1;
        @subtown      = map { $_ . '丁目' } @nums;
        @subtown_kana = map { $_ . 'チョウメ' } @nums;
        $columns->{town_kana} =~ s/\(\d+(?:､\d+)ﾁｮｳﾒ\)$//;
    } elsif ($columns->{town} =~ s/（(\d+)[〜～](\d+)丁目）$//) {
        my($first, $last) = (alnum_z2h($1), alnum_z2h($2));
        @subtown      = map { $_ . '丁目' } $first..$last;
        @subtown_kana = map { $_ . 'チョウメ' } $first..$last;
        $columns->{town_kana} =~ s/\(\d+-\d+ﾁｮｳﾒ\)$//;
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
}

1;
__END__

=encoding utf8

=head1 NAME

Parse::JapaneseZipCode::Row -

=cut
