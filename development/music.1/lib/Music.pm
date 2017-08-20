package Music;

# normal junk #AzA
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

# from perl cookbook..................................+
use Term::Cap;                                        #
my $OSPEED = 9600;                                    #
eval {                                                #
    require POSIX;                                    #
    my $termios = POSIX::Termios->new();              #
    $termios->getattr;                                #
    $OSPEED = $termios->getospeed;                    #
};                                                    #
my $terminal = Term::Cap->Tgetent({OSPEED=>$OSPEED}); #
my $clear = $terminal->Tputs('cl', 1, *STDERR);      #
#.....................................................+

use Digest::MD5 qw(md5_hex);
use Path::Tiny;
use YAML::Tiny qw(LoadFile DumpFile);

use Data::Printer; # use_prototypes=>0;
use Text::Fuzzy;
use Term::UI;
my $TermUI = Term::ReadLine->new($ENV{TERM});

my %Options;
my %Debug;

my @stupid_useless_list = qw/scheme keys all write/;
while (my ($c, $n) = each @stupid_useless_list) {
    $Debug{$n} = 1<<$c;
};

sub _errors ($key, $val) {
    if (exists $Debug{$val}) {
        $Options{$key} ^= $Debug{$val};
    } else {
        $Options{$key} ^= $Debug{$val} = 1 << keys %Debug;
    }
} #ZaZ

sub _CheckDisplay ($db_h) { #AzA
    my %read = $db_h->%*;
    warn "skipping $_", "\n" for grep {! exists $read{$_}} keys %read;
    for (grep {exists $read{$_}} $Options{keys}->@*) {
        my %th = $read{$_}->%*;
        my ($key, $hash) = Mangle($_);
        ($key, $hash) = ($hash, $key) if $Options{flip};
        @th{qw/key hash/} = ($key, $hash);
        p %th;
    }
} #ZaZ

sub _Stripper ($str) { #AzA
    my @excludes = (
        qr/\[.+\]/, qr/\(.+\)/, qr/\{.+\}/,
        qr/<.+>/, qr/(?i:\Wdis[ck]\s+\w+)/,
        qr/\(.+(?!\))/,
    );
    my @removed;
    for (@excludes) {
        my @matched = ($str =~ /($_)/g);
        @matched ? push(@removed, @matched) : next;
        $str =~ s/($_)//g;
    }
#    my ($pre, @post) = split /:/, $str;
#    if (defined $pre) {
#        $str = $pre;
#        push @removed, @post if @post;
#    }
    $str =~ s/^\s*|\s*$//g;
    my %rtn = (stripped => $str, removed => [@removed]);
    return wantarray ? %rtn : \%rtn;
} #ZaZ

sub _SortedLetters ($str) { #AzA rewrites & as and, removes /, converts \W to ' '
    $str =~ s/\&/and/g;
    $str =~ s{/}{}g if $str =~ m{/};
    $str =~ s/\W//g;
    $str =~ s/\s+//g;
    $str = join('', sort split(//, lc $str));;
    return $str;
} #ZaZ

sub Mangle ($str) { #AzA
    my %rtn = _Stripper($str);
    $rtn{sorted} = _SortedLetters($rtn{stripped});
    $rtn{md5} = Digest::MD5->new->add($rtn{sorted})->hexdigest;
    return wantarray ? %rtn : \%rtn;
} #ZaZ

sub LoadRawData ($Filekey, $MangleKey, $Extras) { #AzA
    my ( undef, $self) = split /:+/, (caller(0))[3];
    printf STDERR "loading %s data\n", $Filekey;
    my @lines = $Options{$Filekey}{file}->lines_utf8({chomp=>1});
    my %rtn;
    $rtn{HEADER} = shift @lines;
    $rtn{HEADER} =~ s/^\W//; # in case we have BOM (?)
    my @fields = split /\t/, $rtn{HEADER};
    for my $line (@lines) {
        if (0 < $Options{limit}{$Filekey}) {
            last if ($Options{limit}{$Filekey} and (1+$Options{limit}{$Filekey}) <= keys %rtn);        
        }
        my %tmp;
        @tmp{@fields} = split /\t/, $line;
        my %mangled = Mangle($tmp{$MangleKey});
        if (! exists $rtn{$mangled{sorted}} ) {
            $rtn{$mangled{sorted}} = {%mangled};
#           for (grep {exists $mangled{$_}} $Extras->@*) {
            for ($MangleKey, $Extras->@*) {
                $rtn{$mangled{sorted}}{$_} = $tmp{$_};
            }
        }
        if ($Options{lines}{$Filekey}) {
            push @{$rtn{$mangled{sorted}}{lines}}, $line;
        }
    }
    return wantarray ? %rtn : \%rtn;
} #ZaZ

sub MergeByAlbum ($input) { #AzA
    my %Master = $input->%{master}->%*;
    my @MasterKeys = grep {$_ ne 'HEADER'} keys %Master;
    my %Slave = $input->%{slave}->%*;

    my @SlaveKeys = grep {$_ ne 'HEADER'} keys %Slave;
    my %rtn;

    for my $slavekey (@SlaveKeys) {
        my $fuzzy = Text::Fuzzy->new($slavekey);
        $fuzzy->set_max_distance($Options{fuzzy});
        my @matches = $fuzzy->nearestv(\@MasterKeys);

        if (0 == @matches) {
            $rtn{$slavekey}{MASTER} = 'missing';
        } elsif (1 == @matches) {
            my $match = shift @matches;
            $rtn{$slavekey}{MASTER} = $Master{$match}{USER_NUMBER};
        } else {
            print $clear;
            my @MasterList = map {join(' / ', $_, $Master{$_}->@{qw/ARTIST TITLE/})} @matches;
            push @MasterList, 'skip';
            my $print_me = join ' / ', $Slave{$slavekey}->@{qw/ARTIST ALBUM/}, $slavekey;
            my $choice = $TermUI->get_reply(
                prompt => 'pick a line number: ',
                choices => \@MasterList,
                default => $MasterList[-1],
                print_me => $print_me
            );
            if ($choice eq 'skip') {
                $rtn{$slavekey}{MASTER} = 'skipped';
            } else {
                my ($chosen) = split m{\s/\s}, $choice;
                $rtn{$slavekey}{MASTER} = $Master{$chosen}{USER_NUMBER};
            }
        }
    }

    my $found = grep {$rtn{$_}{MASTER} =~ /\d+/} keys %rtn;
    my $skipped = grep {$rtn{$_}{MASTER} =~ /skipped/} keys %rtn;
    my $missing = grep {$rtn{$_}{MASTER} =~ /missing/} keys %rtn;
    printf STDERR "we found %d matches\n", $found;
    printf STDERR "we skipped %d\n", $skipped;
    printf STDERR "we are missing %d\n", $missing;
    return wantarray ? %rtn : \%rtn;
} #ZaZ

sub MergeSlaveData ($master_a) { #AzA
    my %Master = $master_a->%*;
    my @MasterKeys = keys %Master;
    my ( undef, $self) = split /:+/, (caller(0))[3];
    warn 'loading slave data';

    my @Lines = $Options{slave}{file}->lines_utf8({chomp=>1});
    my @TypeKey = qw/ALBUM ARTIST/;
    my %rtn;
    $rtn{HEADER} = shift @Lines;
    my @fields = split /\t/, $rtn{HEADER};
    for my $line (@Lines) {
        my %tmp;
        @tmp{@fields} = split /\t/, $line;
        my %mangled = Mangle($tmp{ALBUM});
        push @{$mangled{sorted}{tracks}}, $line;
        next if exists $rtn{$mangled{sorted}}{MASTER};
	my $fuzzy = Text::Fuzzy->new($mangled{sorted});
	$fuzzy->set_max_distance($Options{fuzzy});
	my @matches = $fuzzy->nearestv(\@MasterKeys);
        if (0 == @matches) {
            $rtn{$mangled{sorted}}{MASTER} = '????';
        } elsif (1 == @matches) {
            my $master = shift @matches;
            $rtn{$mangled{sorted}}{MASTER} = $Master{$master}{USER_NUMBER};
        } else {
            print $clear;
            my @MasterList = map {$Master{$_}{line}." / $_"} @matches;
            push @MasterList, 'skip';
            my $print_me = join ' / ', @tmp{@TypeKey}, $mangled{sorted};
            my $choice = $TermUI->get_reply(
                prompt => 'pick line: ',
                choices => \@MasterList,
                default => $MasterList[-1],
                print_me => $print_me
            );
            if ($choice eq 'skip') {
                $rtn{$mangled{sorted}}{MASTER} = '????';
            } else {
                ($choice) =~ /^(\d+)/;
                say $choice;
                die;
                $rtn{$mangled{sorted}}{MASTER} = $Master{$choice}{USER_NUMBER};
            }
        }
    }
    my @tracks;
    for my $album (grep { $_ ne 'HEADER'} keys %rtn) {
        push @tracks, map {"$rtn{$album}{MASTER}\t$_"} $rtn{$album}{tracks}->@*;
    }
    $rtn{HEADER} =~ s/^/DISK\t/;
    unshift @tracks, $rtn{HEADER};

    return wantarray ? @tracks : \@tracks;
} #ZaZ

sub ProcessCli (@input) { #AzA
    my ( undef, $name) = split /:+/, (caller(0))[3];
    %Options = ( #AzA
        flip   => 0,
        help   => 0,
        fuzzy  => 5,
        keys   => [],
        limit  => {slave => 0, master => 0},
        lines  => {slave => 0, master => 0},
	slave  => {file => 'slave.tab'},
	master => {file => 'master.tab'},
	debug  => 0,
        quit   => 0,
    ); #ZaZ
    my @options = ( #AzA
        'flip|hash_map',
        'help',
        'fuzzy=i',
        'keys=s',
        'limit=s'  => sub {my ($key, $val) = split /=/, $_[1]; $Options{$_[0]}{$key} = $val},
        'lines=s'  => sub {$Options{$_[0]}{$_[1]} ^= 1},
        'slave=s'  => sub {$Options{$_[0]}{file}  = $_[1]},
        'master=s' => sub {$Options{$_[0]}{file} = $_[1]},
        'debug=s'  => sub {_errors(@_)},
        'quit=s'   => sub {_errors(@_); $Options{debug} ^= $Debug{$_[1]}; },
    ); #ZaZ
    my %help = ( #AzA
        flip   => '',
        help   => '',
        limit  => 'restricts the number of cds read from slave input file',
        fuzzy  => 'level of fuzziness we match to.  default is 3',
        keys   => 'substring to match slave data against for testing.',
        slave  => 'file to read slave data from.  this is what we match FROM',
        master => 'file to read master data from.  this is what we match TO',
        debug  => 'flag a routine for debugging.',
        quit   => 'indicate a routine to die in. see debug.',
         
    ); #ZaZ
    GetOptionsFromArray(\@input, \%Options, @options) or die 'illegal options', "\n";
    if (my $test = $Debug{$name}) {
        warn 'options:', "\n";
        p %Options;
        warn 'files:', "\n";
        p @input;
        die 'exit', "\n" if $Options{quit} & $test;
    }

    for (qw/slave master/) {
        $Options{$_}{file} = readlink $Options{$_}{file} if -l $Options{$_}{file};
        if (-s $Options{$_}{file}) {
            $Options{$_}{file} = path($Options{$_}{file});
        } else {
            die $Options{$_}{file} . 'is not usable', "\n";
        }
    }
    
    return wantarray ? @input : \@input;
} #ZaZ

#sub DumpWork ($ref_h) { #AzA
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
#} #ZaZ

1;

__END__

sub LoadData ($type = $Options{testing}) { #AzA
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
        my ($album_key, $key_pair) = Mangle($album);
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
} #ZaZ

sub WordScore ($astr, $bstr) { #AzA
    my ($short, $long) = (length $astr <= length $bstr) ? ($astr, $bstr) : ($bstr, $astr);
    $short = _SortedLetters($short);
    $long = _SortedLetters($long);
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
} #ZaZ

#sub LoadSlaveData ($data_file, %opts) { #AzA
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
#        my ($album_key, $key_pair) = Mangle($album, $opts{flip});
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
#} #ZaZ

sub CullSingletons ($dmp3_href) { #AzA
    my %dmp3 = %$dmp3_href;
    my %tracks_map = map {$_=>scalar $dmp3{$_}{cd}{tracks}->@*} keys %dmp3;
    my %rtn;
    for (grep {1 < $tracks_map{$_}} keys %tracks_map) {
        $rtn{$_} = {$dmp3{$_}};
    }
    my %singletons = map {$_=>{$dmp3{$_}}} grep {1 == $tracks_map{$_}} keys %tracks_map;
    path('singletons.json')->spew(JSON->new->utf8->encode(\%singletons));
    return wantarray ? %rtn : \%rtn;
} #ZaZ

sub LoadMasterData { #AzA
    my ( undef, $self) = split /:+/, (caller(0))[3];
    warn 'loading master data';
    my @Lines = $Options{master}{file}->lines_utf8({chomp=>1});

    my @TypeKey = qw/TITLE ARTIST/;
    my %rtn;
    $rtn{HEADER} = shift @Lines;
    $rtn{HEADER} =~ s/^\W//; # in case we have BOM (?)
    my @fields = split /\t/, $rtn{HEADER};
    for my $line (@Lines) {
        my %tmp;
        @tmp{@fields} = split /\t/, $line;
        my %mangled = Mangle($tmp{TITLE});
        $rtn{$mangled{sorted}} = {USER_NUMBER => $tmp{USER_NUMBER}, line => $line};
    }
    return wantarray ? %rtn : \%rtn;
} #ZaZ
