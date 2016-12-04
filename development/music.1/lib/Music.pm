package Music;

# vim: ai si sw=4 sts=4 et fdc=4 fmr=AAA,ZZZ fdm=marker

# normal junk #AAA
use warnings;
use strict;
use v5.22;
use experimental qw(smartmatch signatures postderef);

use Getopt::Long qw(GetOptionsFromArray :config pass_through no_ignore_case auto_help);
#my %opts;
#my @opts;
#my @commands;
#GetOptions( \%opts, @opts, @commands ) or die 'something goes here';
#use Pod::Usage;
#use File::Basename;
#use Cwd;

use Digest::MD5 qw(md5_hex);
use Path::Tiny;
use JSON;
use Data::Printer; # use_prototypes=>0;
use Text::Fuzzy;

our %Options;

#BEGIN {
#    use experimental qw(smartmatch);
#    unshift @INC, grep {! ($_ ~~ @INC)} map {"$_"} grep {path($_)->is_dir} map {path("$_/lib")->realpath} '.', '..';
#}
#use Menu;

#ZZZ

sub _CheckDisplay ($db_h) { #AAA
    my %read = $db_h->%*;
    for ($Options{check}->@*) {
        my ($key, $hash) = _GenHashMap($_);
        warn $key, "\n";
        if (exists $read{$key}) {
            my %th = ($key => {$read{$key}->%*});
            p %th;
        } else {
            warn "skipping $_ ($key/$hash)", "\n";
        }
    }
} #ZZZ

sub _ModSpecials ($str) { #AAA rewrites & as and, removes /, converts \W to ' '
    $str =~ s/\&/and/g;
    $str =~ s{/}{}g if $str =~ m{/};
    $str =~ s/\W//g;
    $str =~ s/\s+//g;
    $str = lc $str;
    return $str;
} #ZZZ

sub _GenHashMap ($str) { #AAA
    my $key = join('', sort split(//, _ModSpecials($str)));
#   my $str = JSON->new->utf8->encode(\@substr); # in case we want to use json later.
    my %rtn = ($key => Digest::MD5->new->add($key)->hexdigest);
    %rtn = reverse %rtn if $Options{flip};
    return wantarray ? %rtn : \%rtn;
} #ZZZ

sub WordScore ($astr, $bstr) { #AAA
    my ($short, $long) = (length $astr <= length $bstr) ? ($astr, $bstr) : ($bstr, $astr);
    $short = _ModSpecials($short);
    $long = _ModSpecials($long);
    return 0 if 0 == (length $short)*(length $long);
    warn "comparing $short to $long\n";
    my $score = 0;
    my @short_list = split /\s+/, $short;
    while (my ($ndx_s, $word_s) = each (@short_list)) {
        my @long_list = split /\s+/, $long;
        while (my ($ndx_l, $word_l) = each (@long_list)) {
            if ($word_s eq $word_l) {
                $score += (1+$ndx_s)*(1+$ndx_l);
                $short =~ s/\s?$word_s\s?//;
                $long =~ s/\s?$word_l\s?//;
                $score += WordScore($short, $long);
            }
            last if $score;
        }
        last if $score;
    }
    return $score;
} #ZZZ

sub CullSingletons ($dmp3_href) { #AAA
    my %dmp3 = %$dmp3_href;
    my %tracks_map = map {$_=>scalar $dmp3{$_}{cd}{tracks}->@*} keys %dmp3;
    my %rtn;
    for (grep {1 < $tracks_map{$_}} keys %tracks_map) {
        $rtn{$_} = {$dmp3{$_}};
    }
    my %singletons = map {$_=>{$dmp3{$_}}} grep {1 == $tracks_map{$_}} keys %tracks_map;
    path('singletons.json')->spew(JSON->new->utf8->encode(\%singletons));
    return wantarray ? %rtn : \%rtn;
} #ZZZ

sub Stripper ($str) { #AAA
    my @excludes = (
        qr/\[.+\]/, qr/\(.+\)/, qr/\{.+\}/,
        qr/<.+>/, qr/(?i:\Wdis[ck]\s+\w+)/,
        qr/\(.+(?!\))/,
    );
#       qr/(?i:\W\s*dis[ck][_\s]?\d+\s*\W)/,
#       qr/(?i:\W\s*soundtrack(s)?\s*\W)/,
    my @removed;
    for (@excludes) {
        my ($matched) = ($str =~ /($_)/);
        next unless defined $matched;
        push @removed, $matched;
        $str =~ s/($_)//g;
    }
    $str =~ s/^\s*|\s*$//g;
    return ($str, @removed);
} #ZZZ

#sub LoadSlaveData ($data_file, %opts) { #AAA
#    return undef unless path($data_file)->is_file;
#    my $struct_file = ($data_file =~ s/.tab/.conf/r);
#    return undef unless path($struct_file)->is_file;
#    my $ref = JSON->new->utf8->decode(path($struct_file)->slurp);
#    my %structure = $ref->%*;
#
#    my @db = map {s/ of \d+//;$_} path($data_file)->lines({chomp=>1});
#    my %key = $structure{key}->%{qw/track cd/};
#    my %hash = $structure{hash}->%{qw/track cd misc/};
#    my %slave;
#    $slave{fields} = [my @db_fields = split /\t/, shift @db];
#
#    my %tmp;
#    for my $line (@db) {
#        state $disk;
#        @tmp{@db_fields} = split /\t/, $line;
#        my $track_key = $tmp{$key{track}};
#        my ($album, @removed) = Stripper($tmp{$key{cd}});
#        my ($album_key, $key_pair) = _GenHashMap($album, $opts{flip});
#        if (exists $slave{$album_key}) {
#            $disk++ if exists $slave{$album_key}{$disk}{$track_key};
#            $slave{$album_key}{$disk}{$track_key} = {%tmp{$hash{track}->@*}};
#            if (@removed) {
#                my %t = map {$_=>1} @removed;
#                $t{$_} = 0 for grep {$_ ~~ $slave{$album_key}{cd}{removed}} @removed;
#                push @{$slave{$album_key}{cd}{removed}}, grep {$t{$_} == 1} keys %t;
#            }
#        } else {
#            $disk = 1;
#            $slave{$album_key}{cd} = {%tmp{$hash{cd}->@*}};
#            $slave{$album_key}{cd}{removed} = [@removed] if @removed;
#            $slave{$album_key}{cd}{stripped} = $album; # removed the disk crap.
#            $slave{$album_key}{misc} = {%tmp{$hash{misc}->@*}};
#            $slave{$album_key}{key_pair} = $key_pair if 1 <= $opts{debug};
##           $slave{$album_key}{fuzzy_text} = Text::Fuzzy->new($album_key);
#            $slave{$album_key}{$disk}{$track_key} = {%tmp{$hash{track}->@*}};
#        }
#        last if $opts{limit} and $opts{limit} == keys %slave;
#    }
#    return undef unless keys %slave;
#    _CheckDisplay(\%slave, $opts{check}, $opts{flip}) if $opts{check};
#    my $dump_file = ($data_file =~ s/.tab/.dump/r);
#    path($dump_file)->spew(JSON->new->utf8->pretty->encode(\%slave));
#    #my %rtn = CullSingletons(\%slave);
#    return wantarray ? %slave : \%slave;
#} #ZZZ

sub LoadData ($type) { #AAA
    my @lines = $Options{$type}{file}->lines_utf8({chomp=>1});
    my %structure = JSON->new->utf8->decode($Options{$type}{conf}->slurp)->%*;

    my %rtn;
    my @fields = split /\t/, shift @lines;
    $fields[0] =~ s/.//;

    my %key = $structure{key}->%*;
    my %hash = $structure{hash}->%*;
    my @check = $Options{check}->@*;
    printf STDERR "loading $Options{$type}{file} ...";

    my %tmp;
    for my $line (@lines) {
        @tmp{@fields} = split /\t/, $line;
        my ($album, @removed) = Stripper($tmp{$key{cd}});
        my ($album_key, $key_pair) = _GenHashMap($album);
        my ($id, $artist, $title) = @tmp{$hash{cd}->@*};
        if (exists $rtn{$album_key}{$id}) {
            warn "we got an oopsie for $id ($tmp{$key{cd}})\n";
        } else {
            $rtn{$album_key}{cd} = {%tmp{$hash{cd}->@*}};
            $rtn{$album_key}{cd}{stripped} = $album;
            $rtn{$album_key}{cd}{removed} = @removed ? [@removed] : [];
        }
        last if $Options{limit} and $Options{limit} == keys %rtn;
    }
    warn 'done', "\n";
    return undef unless keys %rtn;
    _CheckDisplay(\%rtn) if $Options{check};
    my $dump_file = path($Options{$type}{file} =~ s/.tab/.dump/r);
    $dump_file->spew(JSON->new->utf8->pretty->encode(\%rtn)) if $Options{debug} & 1<<0;
    return wantarray ? %rtn : \%rtn;
} #ZZZ

sub ProcessCli (@input) { #AAA
    %Options = (
	limit   => 0,
	flip    => 0,
	verbose => 0,
	debug   => 0,
	dump    => 0,
	bad     => 0,
	slave   => {file => 'slave.tab'},
	master  => {file => 'master.tab'},
	check   => [],
    );

    my @options = ( 'flip|hash_map', 'verbose+', 'limit=i', 'debug=i', 'check=s@', 'dump', 'bad',
        'slave=s'  => sub {$Options{slave}{file}  = $_[1]},
        'master=s' => sub {$Options{master}{file} = $_[1]},
    );
    GetOptionsFromArray(\@input, \%Options, @options) or die 'illegal options', "\n";

    for (qw/slave master/) {
        $Options{$_}{file} = readlink $Options{$_}{file} if -l $Options{$_}{file};
        if (-s $Options{$_}{file}) {
            $Options{$_}{file} = path($Options{$_}{file});
            my ($conf) = $Options{$_}{file} =~ s/.tab/.conf/r;
            if (-s $conf) {
                $Options{$_}{conf} = path($conf);
            } else {
                die "no configuration file for $Options{$_}{file}\n";
            }
        } else {
            die $Options{$_}{file} . 'is not usable', "\n";
        }
    }
    
    return wantarray ? @input : \@input;
} #ZZZ

1;
