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

# main #AAA

my @names = Music::ProcessCli(@ARGV) or die 'no files specified to work with', "\n";

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

my %Master = Music::LoadData('master') if 'master' ~~ @names;
my %Slave =  Music::LoadData('slave') if 'slave' ~~ @names;

if ($Music::Options{testing}) {
    if ($Music::Options{debug}) {
        if (1 == @names) {
            my %file = keys %Master ? %Master : %Slave;
            p %file if $Music::Options{debug} & $Music::Debug{debug};
            die 'done with testing', "\n" if $Music::Options{quit} & $Music::Debug{debug};
        } else {
            warn 'we test to see if we can find one Slave in the Master list', "\n";
            my ($test) =  $Music::Options{keys}->@* ? $Music::Options{keys}->@* : keys %Slave;
            warn 'our test case is: ', $test, "\n";
            my %t = $Slave{$test}->%*;
            my %whole = ($test => {%t});
            p %whole;
            my @Master_keys = keys %Master;
            warn 'searching Master for '.$test, "\n";
            my $fuzzy = Text::Fuzzy->new($test);
            $fuzzy->set_max_distance(5);
            my $match = $fuzzy->nearestv(\@Master_keys) or die 'no  match found', "\n";
            my %found = ($match => $Master{$match});
            p %found;
            die 'we exit now', "\n";
        }
    } else {
        die 'makes no sense; testing set but debug is not?', "\n";
    }
}

my %matches;
my @Master_keys = keys %Master;
for my $SlaveCd (keys %Slave) {
    my $fuzzy = Text::Fuzzy->new($SlaveCd);
    $fuzzy->set_max_distance(5); # todo: make this a cli option
    my $master = $fuzzy->nearestv(\@Master_keys);
    $Slave{$SlaveCd}{cd}{INDEX} = $master ? $Master{$master}{cd}{USER_NUMBER} : undef;
}
my %stats;
$stats{matched} = grep {$Slave{$_}{cd}{INDEX} =~ /^\d+$/} keys %Slave;
say $Slave{$_}{cd}{ALBUM} for grep {! defined $Slave{$_}{cd}{MASTER}} keys %Slave;
p %stats;

#if (keys %master) {
#    my @master_keys = grep {$_ ne 'fields'} keys %master;
#    my %master_stripped = map {$master{$_}{cd}{stripped} => $_} @master_keys;
#    warn "we have ".scalar @master_keys." disks in master\n";
#    my %tmp_data = $master{$master_keys[0]}->%*;
#    p %tmp_data;
##   p %master_stripped;
#} else {
#    die "error reading $Music::Options{master}\n";
#}
#
#if (keys %slave) {
#    my @slave_keys = grep {$_ ne 'fields'} keys %slave;
#    my %slave_stripped = map {$slave{$_}{cd}{stripped} => $_} @slave_keys;
#    warn "we have ".scalar @slave_keys." disks in slave\n";
#    my %tmp_data = $slave{$slave_keys[0]}->%*;
#    p %tmp_data;
##   p %slave_stripped;
#} else {
#    die "error reading $Music::Options{slave}\n"
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
#    printf STDERR "checking %4d %s\n", $check++, $slave{$slave_key}{cd}{ALBUM};
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
##            push @{$assigned{$slave{$slave_key}{cd}{ALBUM}}}, $master{$master_key}{cd}{USER_NUMBER};
##            $saved++;
##        }
##    }
##    if (0 == $saved) {
##        $problems{$slave_key}{slave} = {$slave{$slave_key}{cd}->%*};
##        $problems{$slave_key}{master} = {$master{$master_key}{cd}->%*} if $master_key;
##    }
#}
__END__
path('problems.json')->spew(JSON->new->utf8->pretty->encode(\%problems));
path('assigned.json')->spew(JSON->new->utf8->pretty->encode(\%assigned));

#ZZZ

