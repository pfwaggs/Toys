#!/usr/bin/env perl

# vim: ai si sw=4 sts=4 et fdc=4 fmr=AAA,ZZZ fdm=marker

# normal junk #AAA
use warnings;
use strict;
use v5.22;
use experimental qw(signatures postderef smartmatch);

use Getopt::Long qw( :config no_ignore_case auto_help );
#my @commands;
#use Pod::Usage;
#use File::Basename;
#use Cwd;

use Path::Tiny;
use JSON;
use Data::Printer;

#BEGIN {
#    use experimental qw(smartmatch);
#    unshift @INC, grep {! ($_ ~~ @INC)} map {"$_"} grep {path($_)->is_dir} map {path("$_/lib")->realpath} '.', '..';
#}
#use Menu;

#ZZZ

sub _struct_Maker ($patterns_a, $save=undef) {
    my %key;
    my %hash;
    for (@$patterns_a) {
        my ($key1, $key2, $str) = split /:/, $_;
        if ($key1 eq 'key') {
            $key{$key2} = $str if $str;
        } else {
            my (@hash) = split /,/, $str;
            $hash{$key2} = [@hash];
        }
    }
    my %rtn = (key => \%key, hash => \%hash);
    path("$save.conf")->spew(JSON->new->pretty->encode(\%rtn)) if defined $save;
    return %rtn;
}

my $file;
my @patterns;
my @opts = (
    'file=s' => \$file,
    'pattern=s@' => \@patterns,
);

GetOptions( @opts ) or die 'something goes here';
my %struct = _struct_Maker(\@patterns, $file//undef);
p %struct unless defined $file;
