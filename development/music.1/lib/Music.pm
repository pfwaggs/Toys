package Music;

# vim: set ai si sw=4 sts=4 et: fdc=4 fmr=AAA,ZZZ fdm=marker

# normal junk #AAA
use warnings;
use strict;
use v5.22;
use experimental qw(smartmatch signatures postderef);

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

#BEGIN {
#    use experimental qw(smartmatch);
#    unshift @INC, grep {! ($_ ~~ @INC)} map {"$_"} grep {path($_)->is_dir} map {path("$_/lib")->realpath} '.', '..';
#}
#use Menu;

#ZZZ

# _check_Display ($db_hr, $check_ar, $flip) #AAA
sub _check_Display ($db_hr, $check_ar, $flip) {
    my %read = $db_hr->%*;
    for ($check_ar->@*) {
        my ($key, $hash) = _gen_Hash_map($_, $flip);
        say STDERR $key;
        if (exists $read{$key}) {
            my %th = ($key => {$read{$key}->%*});
            p %th;
        } else {
            warn "skipping $_ ($key/$hash)\n";
        }
    }
}
#ZZZ

sub mod_Specials ($str) {
    $str =~ s/\&/and/g;
    $str =~ s{/}{}g if $str =~ m{/};
    $str =~ s/\W/ /g;
    $str = lc $str;
    return $str;
}


# _gen_Hash_map ($str, $flip) #AAA
sub _gen_Hash_map ($str, $flip) {
    $str = mod_Specials($str);
    my $key = join('', sort split //, ($str =~ s/\s+//gr));
#   my $key = join('', sort split //, join('', map {s/\&/and/g; s/\W//g; lc $_} $str ));
#   my $str = JSON->new->utf8->encode(\@substr); # in case we want to use json later.
    my %rtn;
    $rtn{$key} = Digest::MD5->new->add($key)->hexdigest;
    %rtn = reverse %rtn if $flip;
    return wantarray ? %rtn : \%rtn;
}
#ZZZ

sub word_Score ($astr, $bstr) {
    my ($short, $long) = (length $astr <= length $bstr) ? ($astr, $bstr) : ($bstr, $astr);
    $short = mod_Specials($short);
    $long = mod_Specials($long);
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
                $score += word_Score($short, $long);
            }
            last if $score;
        }
        last if $score;
    }
    return $score;
}

# cull_Singletons ($dmp3_href) #AAA
sub cull_Singletons ($dmp3_href) {
    my %dmp3 = %$dmp3_href;
    my %tracks_map = map {$_=>scalar $dmp3{$_}{cd}{tracks}->@*} keys %dmp3;
    my %rtn;
    for (grep {1 < $tracks_map{$_}} keys %tracks_map) {
        $rtn{$_} = {$dmp3{$_}};
    }
    my %singletons = map {$_=>{$dmp3{$_}}} grep {1 == $tracks_map{$_}} keys %tracks_map;
    path('singletons.json')->spew(JSON->new->utf8->encode(\%singletons));
    return wantarray ? %rtn : \%rtn;
}
#ZZZ

# stripper ($str) #AAA
sub stripper ($str) {
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
        push @removed, $matched if defined $matched;
        $str =~ s/($_)//g;
    }
    $str =~ s/^\s*|\s*$//g;
    return ($str, @removed);
}
#ZZZ

# load_Slave ($data_file, %opts) #AAA
sub load_Slave ($data_file, %opts) {
    return undef unless path($data_file)->is_file;
    my $struct_file = ($data_file =~ s/.tab/.conf/r);
    return undef unless path($struct_file)->is_file;
    my $ref = JSON->new->utf8->decode(path($struct_file)->slurp);
    my %structure = $ref->%*;

    my @db = map {s/ of \d+//;$_} path($data_file)->lines({chomp=>1});
    my %key = $structure{key}->%{qw/track cd/};
    my %hash = $structure{hash}->%{qw/track cd misc/};
    my %slave;
    $slave{fields} = [my @db_fields = split /\t/, shift @db];

    my %tmp;
    for my $line (@db) {
        state $disk;
        @tmp{@db_fields} = split /\t/, $line;
        my $track_key = $tmp{$key{track}};
        my ($album, @removed) = stripper($tmp{$key{cd}});
        my ($album_key, $key_pair) = _gen_Hash_map($album, $opts{flip});
        if (exists $slave{$album_key}) {
            $disk++ if exists $slave{$album_key}{$disk}{$track_key};
            $slave{$album_key}{$disk}{$track_key} = {%tmp{$hash{track}->@*}};
            if (@removed) {
                my %t = map {$_=>1} @removed;
                $t{$_} = 0 for grep {$_ ~~ $slave{$album_key}{cd}{removed}} @removed;
                push @{$slave{$album_key}{cd}{removed}}, grep {$t{$_} == 1} keys %t;
            }
        } else {
            $disk = 1;
            $slave{$album_key}{cd} = {%tmp{$hash{cd}->@*}};
            $slave{$album_key}{cd}{removed} = [@removed] if @removed;
            $slave{$album_key}{cd}{stripped} = $album; # removed the disk crap.
            $slave{$album_key}{misc} = {%tmp{$hash{misc}->@*}};
            $slave{$album_key}{key_pair} = $key_pair if 1 <= $opts{debug};
            $slave{$album_key}{$disk}{$track_key} = {%tmp{$hash{track}->@*}};
        }
        last if $opts{limit} and $opts{limit} == keys %slave;
    }
    return undef unless keys %slave;
    _check_Display(\%slave, $opts{check}, $opts{flip}) if $opts{check};
    my $dump_file = ($data_file =~ s/.tab/.dump/r);
    path($dump_file)->spew(JSON->new->utf8->pretty->encode(\%slave));
    #my %rtn = cull_Singletons(\%slave);
    return wantarray ? %slave : \%slave;
}
#ZZZ

# load_Master ($data_file, %opts) #AAA
sub load_Master ($data_file, %opts) {
    return undef unless path($data_file)->is_file;
    my $struct_file = ($data_file =~ s/.tab/.conf/r);
    return undef unless path($struct_file)->is_file;
    my $ref = JSON->new->utf8->decode(path($struct_file)->slurp);
    my %structure = $ref->%*;
    my @db = path($data_file)->lines_utf8({chomp=>1});
    my %master;
    $master{fields} = [split /\t/, shift @db];
    $master{fields}[0] =~ s/.//;
    my @db_fields = $master{fields}->@*;

    my %key = $structure{key}->%*;
    my %hash = $structure{hash}->%*;
    my @check = $opts{check}->@*;
    printf STDERR "loading $data_file ...";

    my %tmp;
    for my $line (@db) {
        @tmp{@db_fields} = split /\t/, $line;
        my ($album, @removed) = stripper($tmp{$key{cd}});
        my ($album_key, $key_pair) = _gen_Hash_map($album, $opts{flip});
        my ($id, $artist, $title) = @tmp{$hash{cd}->@*};
        if (exists $master{$album_key}{$id}) {
            warn "we got an oopsie for $id ($tmp{$key{cd}})\n";
        } else {
            $master{$album_key}{cd} = {%tmp{$hash{cd}->@*}};
            $master{$album_key}{cd}{stripped} = $album;
            $master{$album_key}{cd}{removed} = [@removed] if @removed;
        }
        last if $opts{limit} and $opts{limit} == keys %master;
    }
    print STDERR "done\n";
    return undef unless keys %master;
    _check_Display(\%master, $opts{check}, $opts{flip}) if $opts{check};
    my $dump_file = ($data_file =~ s/.tab/.dump/r);
    path($dump_file)->spew(JSON->new->utf8->pretty->encode(\%master)) if $opts{debug} & 1<<0;
    return wantarray ? %master : \%master;
}
#ZZZ

1;
