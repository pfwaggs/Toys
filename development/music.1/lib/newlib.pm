package newlib;

use strict;
use warnings;
use v5.22;
use experimental qw(signatures postderef);

use Data::Printer;
use Path::Tiny;
use YAML::Tiny qw(LoadFile DumpFile);

use parent qw(Exporter);
our @EXPORT_OK;

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
	my $artistkey = join('', sort(split //, lc $artist =~ s/\W//gr));
	for my $order (keys $data{$artist}->%*) {
	    for my $album (keys $data{$artist}{$order}->%*) {
		my $albumkey = join('', sort(split //, lc $album =~ s/\W//gr));
		$keys{$artist}{$album} = join('/', $artistkey, $albumkey);
	    }
	}
    }
    return wantarray ? %keys : \%keys;
} #ZaZ
1;
