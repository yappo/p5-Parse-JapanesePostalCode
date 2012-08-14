#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.014;
use lib 'lib';
use Parse::JapanesePostalCode;

binmode STDOUT => 'utf8';

my $ken_all = shift;

my $parser = Parse::JapanesePostalCode->new( file => $ken_all );
while (my $obj = $parser->fetch_obj) {
    next unless $obj->town;
    next unless $obj->has_subtown;

    my $ok = 1;
    for my $name (@{ $obj->subtown }) {
        $ok = 0 if $name =~ /(?:その他|を除く|及び)/;
    }
    next if $ok;

    my @line;
    push @line, map { $obj->$_ // '' } qw/
    region_id zip
    pref city town
    build floor
    /;
    if ($obj->has_subtown) {
        push @line, join('/', @{ $obj->subtown });
    }
    say join "\t", map { "[$_]" } @line;
}
