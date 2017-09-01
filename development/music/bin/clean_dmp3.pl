#!/usr/bin/env perl

# normal junk #AzA
use warnings;
use strict;
use v5.22;
use experimental qw(smartmatch postderef signatures);

use Getopt::Long qw( :config no_ignore_case auto_help );
#my %opts;
#my @opts;
#my @commands;
#use Pod::Usage;
#use File::Basename;
#use Cwd;

use Path::Tiny;
use JSON::PP;
use Data::Printer;

#use lib join('/', $ENV{PWD}, 'lib');
#use lib join('/', path($ENV{PWD})->parent, 'lib');
#use Music;

#BEGIN {
#    use experimental qw(smartmatch);
#    unshift @INC, grep {! ($_ ~~ @INC)} map {"$_"} grep {path($_)->is_dir} map {path("$_/lib")->realpath} '.', '..';
#}
#use Menu;

#ZaZ

# rewrite ($db_h, $structure_h) #AzA
sub rewrite ($db_h, $structure_h) {
    my %db = %$db_h;
    my %structure = %$structure_h;
    my %key = $structure{key}->%{qw/track cd/};
    my %hash = $structure{hash}->%{qw/track cd/}; #for now we drop the misc stuff

    my @return;
    for my $title_key (grep {ref $db{$_} eq 'HASH'} keys %db) {
        my @disk_keys = sort {$a <=> $b} grep {/^\d+$/} keys $db{$title_key}->%*;
        for my $disk_key (@disk_keys) {
            my $disk_key_out = sprintf "%02d", $disk_key;
            my @track_keys = sort {$a <=> $b} grep {/^\d+$/} keys $db{$title_key}{$disk_key}->%*;
            for my $track_key (@track_keys) {
                my $track_key_out = sprintf "%02d", $track_key;
                my ($ARTIST, $TRACK, $TIME) = @{$db{$title_key}{$disk_key}{$track_key}}{$hash{track}->@*};
                push @return, join("\t", $db{$title_key}{cd}{$key{cd}}, $disk_key_out, $track_key_out, $TIME, $ARTIST, $TRACK);
            }
        }
    }
    unshift @return, join("\t",qw/ALBUM DISK TRACK TIME ARTIST TITLE/);
    return wantarray ? @return : \@return;
}
#ZaZ

my $dmp3_rgx = qr/(?i:^dmp3.*)\.tab$/;
my ($dmp3_file) = map {$_->basename} path('.')->children($dmp3_rgx);
my %opts = (
    limit   => 0,
    flip    => 0,
    verbose => 0,
    debug   => 0,
    check   => [],
);
my @opts = (
    'flip|hash_map',
    'verbose+',
    'limit=i',
    'check=s@',
);
GetOptions( \%opts, @opts, 'dmp3=s' => \$dmp3_file,) or die "options are not correct\n";

## %structure #AzA
#my %structure = (
#    key => {
#        track => 'TRACK',
#        cd    => 'ALBUM',
#    },
#    hash => {
#        track => [qw/ARTIST TITLE TIME/],
#        cd    => [qw/ALBUM/],
#        misc  => [qw/GENRE DATE/],
#    },
#);
##ZaZ

my $tmp = JSON->new->decode(path('dmp3.conf')->slurp);
my %structure = $tmp->%*;

my %dmp3_db = load_Dmp3($dmp3_file, \%structure, %opts);

for my $key (grep {exists $dmp3_db{$_}{cd}{removed}} grep {$_ ne 'fields'} keys %dmp3_db) {
    warn $key;
    my %tmp= $dmp3_db{$key}{cd}->%*;
    p %tmp;
}

warn "quick check for singletons.\n";
for (grep {ref $_ eq 'HASH'} keys %dmp3_db) {
    my %t = $dmp3_db{$_}->%*;
    p %t;
    my @track_list = keys $t{tracks}->%*;
    if (1 == @track_list) {
        p %t;
        die "found a singleton";
    }
}
warn "hurray! we have no singletons!\n";
my @rewrite = rewrite(\%dmp3_db, \%structure);
path('rewrite.tab')->spew_utf8(map {"$_\n"} @rewrite);

