#!/usr/bin/env perl

# vim: ai si sw=4 sts=4 et fdc=4 fmr=AAA,ZZZ fdm=marker

# normal junk #AAA
use warnings;
use strict;
use v5.22;
use experimental qw(smartmatch signatures postderef autoderef);

use Getopt::Long qw( :config no_ignore_case auto_help );
#use Digest::MD5 qw(md5_hex);
use Path::Tiny;
use JSON;
use Data::Printer colored => 0; # use_prototypes=>0;

use Music;

#ZZZ

my @names = Music::ProcessCli(@ARGV) or die 'no files specified to work with', "\n";

my %Master = Music::LoadMasterData();
my @tracks = Music::MergeSlaveData(\%Master);

path('testing.txt')->spew_utf8(map {$_."\n"} @tracks);
