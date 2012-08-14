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
    next unless $obj->town =~ /(?:地割|一円|の次に番地がくる場合|区画|[０-９](?:丁目|番地|番地?以[上下]|以[上外]|号.?|地割|[線番～])|その他|を除く|[０-９]|丁目|番地|及び|[〜～（）\(\)、「」])/;
    if ($obj->pref eq '北海道') {
        if ($obj->town =~ /(?:\d+[条線]|\d+条通)$/) {
            next unless $obj->town =~ /[〜～（）\(\)、「」]/;
        }
    }
#    next unless $obj->town =~ /丁目/;
    my @line;
    push @line, map { $obj->$_ // '' } qw/
    region_id zip
    /;
#    push @line, map { $obj->$_ // '' } qw/
#    pref_kana city_kana town_kana build_kana
#    /;

    if ($obj->has_subtown) {
        push @line, join('/', @{ $obj->subtown_kana });
    }

    push @line, map { $obj->$_ // '' } qw/
    pref city town
    build floor
    /;
    if ($obj->has_subtown) {
        push @line, join('/', @{ $obj->subtown });
    }

    push @line, map { $obj->$_ // '' } qw/ is_multi_zip is_multi_town /;
 

    say join "\t", map { "[$_]" } @line;
}

