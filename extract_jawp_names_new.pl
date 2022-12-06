#!/usr/bin/env perl

use strict;
use utf8;
use open IO => ':utf8';
use open ':std';

use FindBin;
use File::Basename;
use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat);

my %exists_dict = ();
my %surname_dict = ();
my %name_dict = ();
my %surname_kana_dict = ();
my %name_kana_dict = ();
my %surname_kanji_dict = ();
my %name_kanji_dict = ();

my %opts;
GetOptions(\%opts,
           "wikipedia-data=s",
           "base-name-file=s",
           "blacklist=s"
    );

$| = 1;

if (not exists $opts{"wikipedia-data"} or not exists $opts{"base-name-file"}) {
    my $script_name = basename($FindBin::Script);
    die "$script_name --wikipedia-data <wikipedia-data> --base-name-file <base-name-file> [--blacklist <blacklist>]\n";
}

open IN, "<", $opts{"base-name-file"} or die "$opts{'$base-name-file'}: $!";
while (<IN>) {
    print;
    chomp;
    $exists_dict{$_} = ();
    my @F = split/\t/;
    my @han = split/ /, $F[0]; 
    my @kana = split/ /, $F[1];
    $surname_dict{$han[0]}->{$kana[0]} = ();
    $surname_kana_dict{$kana[0]} = ();
    $surname_kanji_dict{$han[0]} = ();
    $name_dict{$han[1]}->{$kana[1]} = ();
    $name_kanji_dict{$han[1]} = ();
    $name_kana_dict{$kana[1]} = ();
}
close IN;

if (exists $opts{"blacklist"}) {
    my $blacklist = $opts{"blacklist"};

    open IN, "<", $blacklist or die "$blacklist: $!";
    while (<IN>) {
        chomp;
        $exists_dict{$_} = ();
    }
    close IN;
}

open IN, "<", $opts{"wikipedia-data"} or die "opts{'wikipedia-data'}: $!";
while (<IN>) {
    chomp;
    while (m{(\b[\p{sc=Han}\p{sc=Hiragana}\p{sc=Katakana}]{1,5}|(?<!\p{sc=Han})\p{sc=Han}[\p{sc=Han}\p{sc=Hiragana}\p{sc=Katakana}]{1,7}) ([\p{sc=Han}\p{sc=Hiragana}\p{sc=Katakana}]{1,7})\W*(\p{sc=Hiragana}+)\W* \W*(\p{sc=Hiragana}+)(?!\s)\W}g) {
        my ($surname_kanji, $name_kanji, $surname_kana, $name_kana) = ($1, $2, $3, $4);
        next if $surname_kanji =~ m{^\P{sc=Han}$} or $name_kanji =~ m{^\P{sc=Han}$};
        next if ($surname_kanji =~ m{^\p{sc=Hiragana}+$} and $surname_kanji ne $surname_kana) or ($name_kanji =~ m{^\p{sc=Hiragana}+$} and $name_kanji ne $name_kana);
        next if $surname_kanji =~ m{王后|王妃};
        $surname_kanji =~ s{^(?:本名|別名|戸籍名)?((?:である|は|の|が|で|に|と|では)(?!\p{sc=Hiragana}))?}{};
        next if length($surname_kanji) > 4;
        $name_kanji =~ s{の(?:祖?父|祖?母|兄|姉|弟|妹)$}{};
        next if length($name_kanji) > 4;
        next if $surname_kanji eq "" or $name_kanji eq "";
        my $fullname = "$surname_kanji $name_kanji\t$surname_kana $name_kana";
        next if exists $exists_dict{$fullname};
        my $kanji = "$surname_kanji $name_kanji";
        my $kana = "$surname_kana $name_kana";
        if ($kanji =~ m{^((?![炭郷])\p{sc=Han}|司馬|欧陽|諸葛|司徒) (\p{sc=Han}{1,2})$}) {
            my $surname_len = length($1);
            my $name_len = length($2);
            my $regex_yomi = q{\p{sc=Hiragana}(?:[ゃゅょ][うくつんっ]?|[いうきくちつんっ]?)};
            my $regex =  qr{^(?:$regex_yomi){$surname_len} (?:$regex_yomi){$name_len}$};
            next if $kana =~ m{$regex};
        }
        my $name_kanji_kana = $name_kanji;
        $name_kanji_kana =~ tr/ァ-ン/ぁ-ん/;
        if (((exists $surname_dict{$surname_kanji}->{$surname_kana} or exists $name_dict{$name_kanji}->{$name_kana} or $name_kanji_kana eq $name_kana) or (exists $surname_kanji_dict{$surname_kanji} and exists $name_kanji_dict{$name_kanji}) or (exists $surname_kana_dict{$surname_kana} and exists $name_kana_dict{$name_kana})) and length($surname_kana) >= length($surname_kanji) and length($name_kana) >= length($name_kanji)) {
            print "$fullname\n";
            $surname_dict{$surname_kanji}->{$surname_kana} = ();
            $surname_kana_dict{$surname_kana} = ();
            $surname_kanji_dict{$surname_kanji} = ();
            $name_dict{$name_kanji}->{$name_kana} = ();
            $name_kanji_dict{$name_kanji} = ();
            $name_kana_dict{$name_kana} = ();
            $exists_dict{$fullname} = ();
        }
        else {
            1;
        }
    }
}
close IN;
