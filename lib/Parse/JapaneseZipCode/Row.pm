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
    build build_kana floor
/;


for my $name (@COLUMNS) {
    my $sub = sub { $_[0]->{columns}{$name} };
    no strict 'refs';
    *{$name} = $sub;
}

sub columns { @COLUMNS }

sub new {
    my($class, %opts) = @_;

    my $columns = {};
    for my $column (@COLUMNS) {
        $columns->{$column} = delete $opts{$column} if defined $opts{$column};
    }

    my $self = bless {
        katakana_h2z    => 1,
        build_town      => '',
        build_town_kana => '',
        %opts,
        columns      => $columns,
    }, $class;

    $self->fix_town;
    $self->fix_build;
    $self->fix_kana;

    $self;
}

sub fix_town {
    my $self = shift;
    my $columns = $self->{columns};
    if ($columns->{town} eq '以下に掲載がない場合') {
        $columns->{town_kana} = undef;
        $columns->{town}      = undef;
    }
}

sub fix_build {
    my $self = shift;
    return unless $self->{build_town};
    my $columns = $self->{columns};
    my $build_town      = $self->{build_town};
    my $build_town_kana = $self->{build_town_kana};

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

sub fix_kana {
    my $self = shift;
    return unless $self->{katakana_h2z};
    for my $name (qw/ pref_kana city_kana town_kana build_kana pref city town build /) {
        next unless defined $self->{columns}{$name};
        $self->{columns}{$name} = katakana_h2z($self->{columns}{$name});
    }
}

1;
__END__

=encoding utf8

=head1 NAME

Parse::JapaneseZipCode::Row -

=cut
