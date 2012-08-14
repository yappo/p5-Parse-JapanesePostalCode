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
#        pref_kana region_kana district_kana city_kana ward_kana town_kana build_kana
    my @line = map { defined $_ ? $_ : '' } map { $obj->$_ } qw/
        region_id old_zip zip
        pref region district city ward town build floor
        is_multi_zip has_koaza_banchi has_chome is_multi_town
        update_status update_reason
    /;
    say join "\t", map { "[$_]" } @line;
    next unless $obj->has_subtown;
    print "\t";
    say join "/", @{ $obj->subtown };
}
