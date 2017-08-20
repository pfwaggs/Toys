#!/usr/bin/env perl

# normal junk #AzA
use warnings;
use strict;
use v5.22;
use experimental qw(signatures postderef);

use Path::Tiny;
use Data::Printer;

use lib qw(./lib ../lib);

use newlib qw(getDisk);

#ZaZ

my @disk = getDisk(shift);

my @tst = @disk[0..10];
p @tst;
