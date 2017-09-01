package newlib;

use strict;
use warnings;
use v5.22;
use experimental qw(signatures postderef smartmatch);

use Data::Printer;
use Path::Tiny;
use YAML::Tiny qw(LoadFile DumpFile);

use parent qw(Exporter);
our @EXPORT_OK;

sub _ParseDiscAlbum ($str) { #AzA
    my ($disc) = $str =~ /(\W(?i:dis[ck])\s+\d+\W)/;
    $str =~ s/\s+\Q$disc// if $disc;
    $disc = $disc ? $disc =~ s/[[:punct:]]//gr : 'disc 1';
    return ($str, $disc//'disc 1');
} #ZaZ

sub _GenMatchKey ($str) { #AzA
    my $rtn = $str =~ s/\&/and/gr;
    $rtn = join('', sort(split //, lc $rtn =~ s/\W//gr));
    return $rtn;
} #ZaZ

sub _ParseTrack ($str) { #AzA
    return (split / - /, $str, 2);
} #ZaZ

# note that keys should contain ARTIST and ALBUM at a minimum
push @EXPORT_OK, qw(getArtistAlbum); sub getArtistAlbum ($file, @keys) { #AzA
    die "keys missing ARTIST" unless /ARTIST/ ~~ @keys;
    die "keys missing ALBUM" unless /ALBUM/ ~~ @keys;
    my %rtn;
    my @lines = path($file)->lines_utf8({chomp=>1});
    # first line contains field names.
    my @fields = split /\t/, shift @lines;
    for (@lines) {
	my $t = {};
	$t->@{@fields} = split /\t/, $_;
	my ($artist, $album, $disc) = ($t->{ARTIST}, _ParseDiscAlbum($t->{ALBUM}));
	$rtn{$artist}{match} = _GenMatchKey($artist) unless $artist ~~ %rtn;
	$rtn{$artist}{$album}{match} = _GenMatchKey($album) unless $album ~~ $rtn{$artist};
	if (/TRACK/ ~~ @fields) {
	    my ($key, $val) = _ParseTrack($t->{TRACK});
	    $rtn{$artist}{$album}{$disc}{$key} = $val;
	}
    }
    return wantarray ? %rtn : \%rtn;
} #ZaZ

push @EXPORT_OK, qw(getDisk); sub getDisk ($file) { #AzA
    my @rtn;
    my @lines = path($file)->lines_utf8({chomp=>1});
    # first line contains field names.
    my @fields = split /\t/, shift @lines;
    for (@lines) {
	my %thash = ();
	%thash->@{@fields} = split /\t/, $_;
	push @rtn, \%thash;
    }
    return wantarray ? @rtn : \@rtn;
} #ZaZ

# this routine reads track names along with disk info. for dmp3 data
push @EXPORT_OK, qw(getSongs); sub getSongs ($file) { #AzA
    my %rtn;
    my @lines = path($file)->lines_utf8({chomp=>1});
    my @fields = split /\t/, shift @lines;
    for (@lines) {
	my %dmp3 = ();
	%dmp3->@{@fields} = split /\t/, $_;
	my $order  = $dmp3{ORDER};
	my $artist = $dmp3{ARTIST};
	my $album  = $dmp3{ALBUM};
	my $track  = $dmp3{TRACK};
	my $d = 1;
	if ($album =~ /(?i:disc \d)/) {
	    ($d) = $album =~ /(?i:disc)\s+(\d+)/;
	    $album = $album =~ s/(\s+\W(?i:disc)\s+\d+\W)//r;
	}
	$d = sprintf "%02d", $d;
	my ($t) = $track =~ /^(\d+)/;
	$rtn{$artist}{$order}{$album}{$d}{$t} = $track;
    }
    return wantarray ? %rtn : \%rtn;
} #ZaZ

push @EXPORT_OK, qw(makeKeys); sub makeKeys ($data) { #AzA
    my %keys;
    my %data = $data->%*;
    for my $artist (keys %data) {
	my $artistKey = $artist =~ s/\&/and/gr;
	$artistKey =~ s/\W//g;
	$artistKey = join('', sort(split //, lc $artistKey));
	for my $order (keys $data{$artist}->%*) {
	    for my $album (keys $data{$artist}{$order}->%*) {
		my $albumKey = $album =~ s/\&/and/gr;
		$albumKey =~ s/\W//g;
		$albumKey = join('', sort(split //, lc $albumKey));
		$keys{$artist}{$album} = join('/', $artistKey, $albumKey);
	    }
	}
    }
    return wantarray ? %keys : \%keys;
} #ZaZ

1;

