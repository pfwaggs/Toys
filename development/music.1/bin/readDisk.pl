#!/usr/bin/env perl

# normal junk #AzA
use warnings;
use strict;
use v5.22;
use experimental qw(signatures postderef);

use Path::Tiny;
use Data::Printer;

use lib qw(./lib ../lib);

use newlib qw(getArtistAlbum);

#ZaZ

# make sure the listed keys includes ARTIST and ALBUM
my $file = shift;
my @keyList = $file =~ /dmp3/ ? qw/ARTIST ALBUM/ : qw/ARTIST USER_NUMBER ALBUM/;

my %disk = getArtistAlbum($file, @keyList);

my ($key) = keys %disk;

say $key;
p $disk{$key};
