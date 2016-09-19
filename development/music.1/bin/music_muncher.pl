#!/usr/bin/env perl

# vim: set ai si sw=4 sts=4 et : *fdc=4 fmr=AAA,ZZZ fdm=marker*/

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
my $master_file = 'master.tab';
my $slave_file = 'slave.tab';

my %opts = (
    limit       => 0,
    flip        => 0,
    verbose     => 0,
    debug       => 0,
    dump        => 0,
    bad         => 0,
    check       => [],
);
#    master_file => $master_file,
#    master_conf => $master_conf,
#    slave_file  => $slave_file
#    slave_conf  => $slave_conf,
my @opts = ( 'flip|hash_map', 'verbose+', 'limit=i', 'debug=i', 'check=s@', 'dump', 'bad',);

GetOptions( \%opts, @opts, 'slave=s'  => \$slave_file, 'master=s' => \$master_file,) or die "options are not correct\n";
my $slave_conf = ($slave_file =~ s/tab/conf/r);
my $master_conf = ($master_file =~ s/tab/conf/r);

if ($opts{dump}) {
    p %opts;
    warn 'slave_file is '.($slave_file//'empty')."\n";
    warn 'master_file is '.($master_file//'empty')."\n";
}


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

my %structure;
my $in = JSON->new->decode(path('slave.conf')->slurp);
$structure{slave} = {$in->%*};
$in = JSON->new->decode(path('master.conf')->slurp);
$structure{master} = {$in->%*};

my %disks = (master => [], slave => []);
my %master_data;
%master_data = Music::load_Master($master_file,%opts);
die "error reading $master_file\n" if ! %master_data;

my @master_keys = grep {$_ ne 'fields'} keys %master_data;
my %master_stripped = map {$master_data{$_}{cd}{stripped} => $_} @master_keys;
warn "we have ".scalar @master_keys." disks in master\n";
p %master_stripped;

my %slave_data = Music::load_Slave($slave_file, %opts);
die "error reading $slave_file\n" if ! %slave_data;

my @slave_keys = grep {$_ ne 'fields'} keys %slave_data;
my %slave_stripped = map {$slave_data{$_}{cd}{stripped} => $_} @slave_keys;
warn "we have ".scalar @slave_keys." disks in slave\n";
p %slave_stripped;


my %problems;
my %assigned;
my $check = 1;
for my $stripped_slave (keys %slave_stripped) {
    my $slave_key = $slave_stripped{$stripped_slave};
    printf STDERR "checking %4d %s\n", $check++, $slave_data{$slave_key}{cd}{ALBUM};

    my $saved = 0;
    my $master_key;
    for my $stripped_master (keys %master_stripped) {
        my $score = Music::word_Score($stripped_slave, $stripped_master);
        say join ("\t", $stripped_slave, $stripped_master, $score);
        say '';
    }
        
#        if ($stripped_master =~ /$stripped_slave/ || $stripped_slave =~ /$stripped_master/) {
#            $master_key = $master_stripped{$stripped_master};
##               warn "stripped_master ".$stripped_master."\n";
#            push @{$assigned{$slave_data{$slave_key}{cd}{ALBUM}}}, $master_data{$master_key}{cd}{USER_NUMBER};
#            $saved++;
#        }
#    }
#    if (0 == $saved) {
#        $problems{$slave_key}{slave} = {$slave_data{$slave_key}{cd}->%*};
#        $problems{$slave_key}{master} = {$master_data{$master_key}{cd}->%*} if $master_key;
#    }
}
__END__
path('problems.json')->spew(JSON->new->utf8->pretty->encode(\%problems));
path('assigned.json')->spew(JSON->new->utf8->pretty->encode(\%assigned));

#ZZZ

