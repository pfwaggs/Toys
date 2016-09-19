#!/usr/bin/env perl

# vim: ai si sw=4 sts=4 et fdc=4 fmr=AAA,ZZZ fdm=marker

# normal junk #AAA
use warnings;
use strict;
use v5.22;
use experimental qw(signatures postderef);

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

#ZZZ

my @test_ary;
my @lines = path(shift)->lines_utf8({chomp=>1});
#my @lines = path(shift)->slurp;
my @keys = split /\t/, shift @lines; # should dump the fields;
$keys[0] =~ s/.//; # first char is wide.  blech.
for (@lines) {
    my %thash = ();
#    my @bob = split /\t/, $_;
#    say 'one';
#    p @bob;
#    @bob = map {s/^\"|\"$//gr} @bob;
#    say 'two';
#    p @bob;
#    @bob = map {s/\"//gr} @bob;
#    say 'three';
#    p @bob;
#    die;
   @thash{@keys} = split /\t/, $_;
   p %thash;
   push @test_ary, {%thash};
}

p @test_ary;
