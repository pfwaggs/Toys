#!/usr/bin/env perl

# normal junk #AzA
use warnings;
use strict;
use v5.22;
use experimental qw(signatures postderef smartmatch);

#use Getopt::Long qw( :config no_ignore_case auto_help );
#my %opts;
#my @opts;
#my @commands;
#GetOptions( \%opts, @opts, @commands ) or die 'something goes here';
#use Pod::Usage;
#use File::Basename;
#use Cwd;

use Path::Tiny;
use JSON::PP;
use Data::Printer;

#BEGIN {
#    use experimental qw(smartmatch);
#    unshift @INC, grep {! ($_ ~~ @INC)} map {"$_"} grep {path($_)->is_dir} map {path("$_/lib")->realpath} '.', '..';
#}
#use Menu;

#ZaZ

#####################
# %structure1 #AzA
my %structure1 = (
    readerware => {
        key => { cd => 'TITLE', },
        hash => { cd => [qw/USER_NUMBER ARTIST TITLE/]},
    },
    dmp3 => {
        key => {
            track => 'TRACK',
            cd    => 'ALBUM',
        },
        hash => {
            track => [qw/ARTIST TITLE TIME/],
            cd    => [qw/ALBUM/],
            misc  => [qw/GENRE DATE/],
        },
    },
);
#ZaZ
######################

# %structure2 #AzA
my %structure2 = (
    key => {
        track => 'TRACK',
        cd    => 'ALBUM',
    },
    hash => {
        track => [qw/ARTIST TITLE TIME/],
        cd    => [qw/ALBUM/],
        misc  => [qw/GENRE DATE/],
    },
);
#ZaZ

p $structure1{dmp3}->%*;
p $structure1{readerware}->%*;

p %structure2;
