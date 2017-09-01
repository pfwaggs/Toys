#!/usr/bin/env perl

# vim: ai si sw=4 sts=4 et

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
#use Term::ReadLine;
#use Term::UI;

use JSON;
use Path::Tiny;
use YAML::Tiny qw(LoadFile DumpFile);
use Data::Printer;

#ZZZ

my @json = path('.')->children(qr/.(json|jsn)$/);

for (@json) {
    my %data = JSON->new->utf8->decode($_->slurp())->%*;
    my $name = $_ =~ s/(json|jsn)/yaml/r;
    DumpFile($name,\%data);
}
