#!/usr/bin/env perl

# vim: ai si sw=4 sts=4 et fdc=4 fmr=AAA,ZZZ fdm=marker

# normal junk #AAA
use warnings;
use strict;
use v5.22;
use experimental qw(smartmatch signatures postderef);

use Getopt::Long qw( :config no_ignore_case auto_help );
#use Digest::MD5 qw(md5_hex);
use Path::Tiny;
use JSON;
use Data::Printer colored => 0; # use_prototypes=>0;

use Music;

#ZZZ

# main #AAA

Music::ProcessCli(@ARGV);

## %structure #AAA
#my %structure = (
#    master => {
#        key => { cd => 'TITLE', },
#        hash => { cd => [qw/USER_NUMBER ARTIST TITLE/]},
#    },
#    slave => {
#        key => {
#            track => 'TRACK',
#            cd    => 'ALBUM',
#        },
#        hash => {
#            track => [qw/ARTIST TITLE TIME/],
#            cd    => [qw/ALBUM/],
#            misc  => [qw/GENRE DATE/],
#        },
#    },
#);
##ZZZ

#my $master_file = $Music::Options{master}//'master.tab';
if (defined $Music::Options{testing}) {
    my %tmp_data = Music::LoadData();
    Music::DumpWork(\%tmp_data) if $Music::Options{debug};
}
die 'done with testing', "\n" if $Music::Options{debug} & 1;

#if (keys %master_data) {
#    my @master_keys = grep {$_ ne 'fields'} keys %master_data;
#    my %master_stripped = map {$master_data{$_}{cd}{stripped} => $_} @master_keys;
#    warn "we have ".scalar @master_keys." disks in master\n";
#    my %tmp_data = $master_data{$master_keys[0]}->%*;
#    p %tmp_data;
##   p %master_stripped;
#} else {
#    die "error reading $master_file\n";
#}
#
#my $slave_file = $opts{slave}//'slave.tab';
#my %slave_data = Music::LoadSlaveData($slave_file, %opts);
#if (keys %slave_data) {
#    my @slave_keys = grep {$_ ne 'fields'} keys %slave_data;
#    my %slave_stripped = map {$slave_data{$_}{cd}{stripped} => $_} @slave_keys;
#    warn "we have ".scalar @slave_keys." disks in slave\n";
#    %tmp_data = $slave_data{$slave_keys[0]}->%*;
#    p %tmp_data;
##   p %slave_stripped;
#} else {
#    die "error reading $slave_file\n"
#}
#
##for my $base (qw/master slave/) {
##    $init_files{file}{$base} = $opts{$base}//"$base.tab";
###   $init_files{conf}{$base} = ($init_files{file}{$base} =~ s/tab/conf/r);
##    $init_files{data}{$base} = {$dispatch{$base}($init_files{file}{$base})};
##    $init_files{keys}{$base} = [grep {$_ ne 'fields'} keys $init_files{data}{$base}];
##    $init_files{stripped}{$base} = {map {$init_files{data}{$base}{$_}{cd}{stripped} => $_} $init_files{keys}{$base};
##}
#
#my %problems;
#my %assigned;
#my $check = 1;
#for my $stripped_slave (keys %slave_stripped) {
#    my $slave_key = $slave_stripped{$stripped_slave};
#    printf STDERR "checking %4d %s\n", $check++, $slave_data{$slave_key}{cd}{ALBUM};
#
#    my $saved = 0;
#    my $master_key;
#    for my $stripped_master (keys %master_stripped) {
#        my $score = Music::WordScore($stripped_slave, $stripped_master);
#        say join ("\t", $stripped_slave, $stripped_master, $score);
#        say '';
#    }
#        
##        if ($stripped_master =~ /$stripped_slave/ || $stripped_slave =~ /$stripped_master/) {
##            $master_key = $master_stripped{$stripped_master};
###               warn "stripped_master ".$stripped_master."\n";
##            push @{$assigned{$slave_data{$slave_key}{cd}{ALBUM}}}, $master_data{$master_key}{cd}{USER_NUMBER};
##            $saved++;
##        }
##    }
##    if (0 == $saved) {
##        $problems{$slave_key}{slave} = {$slave_data{$slave_key}{cd}->%*};
##        $problems{$slave_key}{master} = {$master_data{$master_key}{cd}->%*} if $master_key;
##    }
#}
#__END__
#path('problems.json')->spew(JSON->new->utf8->pretty->encode(\%problems));
#path('assigned.json')->spew(JSON->new->utf8->pretty->encode(\%assigned));

#ZZZ

