#!/usr/bin/env perl

# vim: ai si sw=4 sts=4 et fdc=4 fmr=AAA,ZZZ fdm=marker

# normal junk #AAA
use warnings;
use strict;
use v5.22;
use experimental qw(postderef signatures smartmatch);

#use Getopt::Long qw( :config no_ignore_case auto_help );
#my %opts;
#my @opts;
#my @commands;
#GetOptions( \%opts, @opts, @commands ) or die 'something goes here';
#use Pod::Usage;
#use File::Basename;
#use Cwd;

use Path::Tiny;
use JSON;
use Data::Printer;

#ZZZ

my @data = path(shift)->lines_utf8({chomp=>1});
my @fields = split /\t/, shift @data;
my %content;
my @output;
my @reject;
my @desire = qw/DISK DN TN ARTIST ALBUM TITLE/;
for my $line (@data) {
    %content = ();
    @content{@fields} = split /\t/, $line;
    my ($cd) = ($content{ALBUM} =~ /(?i:dis[ck])\W+(\d+)/);
    $content{DN} = defined $cd ? sprintf("%02d", $cd) : '01';
    
    if ($content{TRACK} =~ /^\d+$/) {
        $content{TN} = $content{TRACK};
    } else {
        warn 'incorrect TRACK '. $line, "\n";
        ($content{TN}, my $count) = $content{TRACK} =~ /(\d+)\D+(\d+)/;
    }
    $content{TN} = sprintf("%02d", $content{TN});
    push @output, join "\t", @content{@desire};
}
warn 'writing file!', "\n";
unshift @output, join "\t", @desire;
path('newstructure.txt')->spew_utf8(map {$_."\n"} @output);
