#!/usr/bin/env perl

# vim: ai si sw=4 sts=4 et fdc=4 fmr=AAA,ZZZ fdm=marker

# normal junk #AAA
use warnings;
use strict;
use v5.18;

#use Getopt::Long qw( :config no_ignore_case auto_help );
#my %opts;
#my @opts;
#my @commands;
#GetOptions( \%opts, @opts, @commands ) or die 'something goes here';
#use Pod::Usage;
#use File::Basename;
#use Cwd;

use Digest::MD5 qw(md5_hex);
use Path::Tiny;
use JSON::PP;
use Data::Printer;

#BEGIN {
#    use experimental qw(smartmatch);
#    unshift @INC, grep {! ($_ ~~ @INC)} map {"$_"} grep {path($_)->is_dir} map {path("$_/lib")->realpath} '.', '..';
#}
#use Menu;

#ZZZ

#album {
#    album_meta { cd_meta},
#    tracks [ {track time} ...],
#    }

my @fields = qw/Track Artist Title Number Time Genre Release/;
my @cd_keys = qw/Artist Title Genre Release/;
my @track_keys = qw/Track Number Time/;

sub _gen_Meta_hash {
    my %input = %{shift @_};
    # for clarity
    my %album = %{$input{album}};
    my @keys = @{$input{keys}};
#   my @substr = sort split //, join('',map {s/\W//g; lc $_} @album{@keys});
    my @substr = @album{@keys};
    my $str = JSON::PP->new->utf8->encode(\@substr); # join('',@substr);
    my $md5 = Digest::MD5->new->add($str);
    return $md5->hexdigest;
}

my @content;
my %content_struct;

for my $line (path(shift)->lines({chomp=>1})) {
    my %track = ();
    my %cd = ();
    my %tmp;
    @tmp{@fields} = split /\t/, $line;
    @cd{@cd_keys}       = @tmp{@cd_keys};
    @track{@track_keys} = @tmp{@track_keys};
    my $key = _gen_Meta_hash({album=>\%cd, keys=>\@cd_keys});

    if (exists $content_struct{$key}) {
	push $content_struct{$key}{tracks}, {%track};
    } else {
	push @content, {%content_struct} if keys %content_struct;
	%content_struct = ();
	$content_struct{$key}{cd} = {%cd};
	$content_struct{$key}{tracks} = [{%track}];
    }

    last if @content > 0;
}
path('output.json')->spew(JSON::PP->new->utf8->pretty->encode(\@content));
