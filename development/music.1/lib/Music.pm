package Music;

# vim: ai si sw=4 sts=4 et fdc=4 fmr=AAA,ZZZ fdm=marker

# normal junk #AAA
use warnings;
use strict;
use v5.22;
use experimental qw(smartmatch signatures postderef autoderef);

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
our %Debug;
our @Lines;
my @stupid_useless_list = qw/scheme keys all write/;
while (my ($c, $n) = each @stupid_useless_list) {
    $Debug{$n} = 1<<$c;
};

sub _errors ($key, $val) {
    my $next = keys %Debug;
    if (exists $Debug{$val}) {
        $Options{$key} ^= $Debug{$val};
    } else {
        $Options{$key} ^= $Debug{$val} = 1<<$next;
    }
} #ZZZ

#ZZZ

sub _CheckDisplay ($db_h) { #AAA
    my %read = $db_h->%*;
    warn "skipping $_", "\n" for grep {! exists $read{$_}} keys %read;
    for (grep {exists $read{$_}} $Options{keys}->@*) {
        my %th = $read{$_}->%*;
        my ($key, $hash) = _GenHashMap($_);
        ($key, $hash) = ($hash, $key) if $Options{flip};
        @th{qw/key hash/} = ($key, $hash);
        p %th;
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

sub LoadMasterData {
    my ( undef, $self) = split /:+/, (caller(0))[3];
    warn 'loading master data';
    @Lines = $Options{master}{file}->lines_utf8({chomp=>1});

    my @TypeKey = qw/TITLE ARTIST/;
    my %rtn;
    $rtn{HEADER} = shift @Lines;
    $rtn{HEADER} =~ s/^\W//;
    my @fields = split /\t/, $rtn{HEADER};
    for my $line (@Lines) {
        my %tmp;
        @tmp{@fields} = split /\t/, $line;
        my ($album, @removed) = Stripper($tmp{TITLE});
        $album = join('', sort split(//, _ModSpecials($album)));
        $rtn{$album} = {USER_NUMBER => $tmp{USER_NUMBER}, line => $line};
    }
    return wantarray ? %rtn : \%rtn;
}

sub MergeSlaveData ($master_a) {
    my %Master = $master_a->%*;
    my @MasterKeys = keys %Master;
    my ( undef, $self) = split /:+/, (caller(0))[3];
    warn 'loading slave data';

    @Lines = $Options{slave}{file}->lines_utf8({chomp=>1});
    my @TypeKey = qw/ALBUM ARTIST/;
    my %rtn;
    $rtn{HEADER} = shift @Lines;
    my @fields = split /\t/, $rtn{HEADER};
    for my $line (@Lines) {
        my %tmp;
        @tmp{@fields} = split /\t/, $line;
        my ($album, @removed) = Stripper($tmp{ALBUM});
        $album = join('', sort split(//, _ModSpecials($album)));
        push @{$rtn{$album}{tracks}}, $line;
        next if exists $rtn{$album}{MASTER};
	my $fuzzy = Text::Fuzzy->new($album);
	$fuzzy->set_max_distance(5); # todo: make this a cli option
	my @matches = $fuzzy->nearestv(\@MasterKeys);
        if (1 < @matches) {
            warn 'multiple matches for '.join(' / ',@tmp{@TypeKey}), "\n";
            say "\t$_" for @matches;
        } else {
            my $master = shift @matches;
            $rtn{$album}{MASTER} = $master =~ /^\w+$/ ? $Master{$master}{USER_NUMBER} : '????';
        }
    }
    my @tracks;
    for my $album (grep { $_ ne 'HEADER'} keys %rtn) {
        push @tracks, map {"$rtn{$album}{MASTER}\t$_"} $rtn{$album}{tracks}->@*;
    }
    $rtn{HEADER} =~ s/^/DISK\t/;
    unshift @tracks, $rtn{HEADER};

    return wantarray ? @tracks : \@tracks;
}

sub LoadData ($type = $Options{testing}) { #AAA
    my ( undef, $name) = split /:+/, (caller(0))[3];
    warn 'loading '.$type, "\n";
    my %structure = JSON->new->utf8->decode($Options{$type}{conf}->slurp)->%*;
    @Lines = $Options{$type}{file}->lines_utf8({chomp=>1});

    printf STDERR "loading $Options{$type}{file} ...";
    my %key = $structure{key}->%*;
    my %hash = $structure{hash}->%*;

    if (exists $Debug{$name} and $Options{debug} & $Debug{$name}) {
        warn 'key is:', "\n";
        p %key;
        warn 'hash is:', "\n";
        p %hash;
        die "exit $name\n" if $Options{quit} & $Debug{$name};
    }

    my @TypeKey = $structure{TypeKey}->@*;
    my %rtn;
    my @fields = split /\t/, shift @Lines;
    $fields[0] =~ s/^\W//;

    my %tmp;
    for my $line (@Lines) {
        last if $Options{limit} and $Options{limit} == keys %rtn;
        @tmp{@fields} = split /\t/, $line;
        my $TypeKey = join('.', @tmp{@TypeKey});
        my ($album, @removed) = Stripper($tmp{$key{cd}});
        my ($album_key, $key_pair) = _GenHashMap($album);
        my ($id, $artist, $title) = @tmp{$hash{cd}->@*};
        if (exists $rtn{$album_key}{$id}) {
            warn "we got an oopsie for $id ($tmp{$key{cd}})\n";
        } else {
            $rtn{$album_key}{cd} = {%tmp{$hash{cd}->@*}};
            $rtn{$album_key}{cd}{stripped} = $album;
            $rtn{$album_key}{cd}{removed} = @removed ? [@removed] : [];
            $rtn{$album_key}{cd}{key} = $album_key;
            $rtn{$album_key}{cd}{key_pair} = $key_pair;
            $rtn{$album_key}{cd}{uc $type} = Digest::MD5->new->add($TypeKey)->hexdigest;
        }
    }
    unshift @Lines, join("\t", @fields);
    printf STDERR "done\n%s has %-4d keys\n", $type, scalar keys %rtn;
    return keys %rtn ? (wantarray ? %rtn : \%rtn) : undef;
} #ZZZ

sub ProcessCli (@input) { #AAA
    my ( undef, $name) = split /:+/, (caller(0))[3];
    %Options = (
        quit    => 0, limit => 0, flip => 0,
	verbose => 0, debug => 0, dump => 0,
        help    => 0, testing => 0,
        keys => [],
	slave   => {file => 'slave.tab'},
	master  => {file => 'master.tab'},
    );

    my @options = (
        'flip|hash_map', 'verbose+',
        'dump', 'testing', 'help',
        'limit=i', 'keys=s',
        'slave=s'  => sub {$Options{$_[0]}{file}  = $_[1]},
        'master=s' => sub {$Options{$_[0]}{file} = $_[1]},
        'debug=s' => sub {_errors(@_)},
        'quit=s' => sub {_errors(@_); $Options{debug} |= $Debug{$_[0]}; },
    );
    GetOptionsFromArray(\@input, \%Options, @options) or die 'illegal options', "\n";
    if (my $test = $Debug{$name}) {
        warn 'options:', "\n";
        p %Options if $Options{debug} & $test;
        warn 'files:', "\n";
        p @input;
        die 'exit', "\n" if $Options{quit} & $test;
    }

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

# ||||||||||
# 9876543210  debug option value
# xxxxxxxxxx  |
#       ||||_ 1 immediate quit after first dump
#       |||__ 2 display options
#       ||___ 3 display entries for specified keys
#       |____ 4 display all entries

#sub DumpWork ($ref_h) { #AAA
#    my $type = $Options{testing};
#    if ($Options{debug} & $Debug{options}) {
#        p $ref_h;
#    }
#    if ($Options{debug} & $Debug{keys}) { # hmmm.  maybe print it out slected keys instead
#        _CheckDisplay($ref_h) if $Options{keys}->@*;
#    }
#    if ($Options{debug} & $Debug{all}) { # hmmm.  maybe print it out slected keys instead
#        p $ref_h;
#    }
#    if ($Options{debug} & $Debug{write}) {
#        my $dump_file = path($Options{$type}{file} =~ s/.tab/.dump/r);
#        $dump_file->spew(JSON->new->utf8->pretty->encode($ref_h));
#    }
#} #ZZZ

1;
