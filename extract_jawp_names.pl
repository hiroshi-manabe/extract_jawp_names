#!/usr/bin/env perl

use strict;
use utf8;
use open IO => ':utf8';
use open ':std';

my $page = "";
while (<STDIN>) {
    if (m{^\s*<page>}) {
        $page = "";
    }
    $page .= $_;
    if (m{^\s*</page>}) {
        next if $page !~ m{\[\[Category:.+(人物|年生|年没)\b}i;

        $page =~ m{<title>(.+?)</title>};
        my $name = $1;

        $page =~ s{\{\{[^\|\}]+?フォント\|(.+?)\}\}}{$1}g;
        $page =~ s{\{\{lang\|[^\|]*\|([^\}]*)\}\}}{$1}g;
        $page =~ s{&amp;#(\d+);}{chr($1)}eg;
        $page =~ s{&amp;#x([A-Fa-f0-9]+);}{chr(hex($1))}eg;

        next if $page !~ m{\{\{(?:DEFAULTSORT|デフォルトソート):(.+?)\}\}}i;

        my $defaultsort = $1;
        $defaultsort =~ tr/ァ-ヴ/ぁ-ゔ/;
        $defaultsort =~ tr/ぁぃぅぇぉっゃゅょゎ/あいうえおつやゆよわ/;
        $defaultsort =~ tr/ゔがぎぐげござじずぜぞだぢづでどばびぶべぼぱぴぷぺぽ/うかきくけこさしすせそたちつてとはひふへほはひふへほ/;
        $defaultsort =~ tr/ぁ-ゔ//cd;
        
        $name =~ s{ \(.+\)}{};
        my @names = ($name);
        if ($page =~ m{\{\{記事名の制約\|title=([^|\}]+)}) {
            push @names, $1;
        }
        my @name_regexps = map {
            join("\\W*", map { quotemeta($_) } split(//, $_));
        } @names;
        my $name_regexp = "";
        if (scalar(@names) == 2 and length($names[0]) == length($names[1])) {
            for (my $i = 0; $i < length($names[0]); ++$i) {
                my $ch1 = quotemeta(substr($names[0], $i, 1));
                my $ch2 = quotemeta(substr($names[1], $i, 1));
                $name_regexp .= ($ch1 eq $ch2) ? $ch1 : "(?:$ch1|$ch2)";
                $name_regexp .= "\\W*" if $i != length($names[0]) - 1;
            }
        }
        else {
            $name_regexp = "(?:".join("|", @name_regexps).")";
        }

        my @chars = split//, $defaultsort;
        my @ambiguous_chars = ();
        
        for (my $i = 0; $i < scalar(@chars); ++$i) {
            my $ch = $chars[$i];
            my @chs = ($ch);
            @chs = map {
                if (m{[あいうえおつやゆよわ]}) {
                    my $c = $_;
                    $c =~ tr/あいうえおつやゆよわ/ぁぃぅぇぉっゃゅょゎ/;
                    ($_, $c);
                }
                else {
                    $_;
                }
            } @chs;
            @chs = map {
                if (m{[うかきくけこさしすせそたちつてとはひふへほ]}) {
                    my $c = $_;
                    $c =~ tr/うかきくけこさしすせそたちつてとはひふへほ/ゔがぎぐげござじずぜぞだぢづでどばびぶべぼ/;
                    ($_, $c);
                }
                else {
                    $_;
                }
            } @chs;
            @chs = map {
                if (m{[はひふへほ]}) {
                    my $c = $_;
                    $c =~ tr/はひふへほ/ぱぴぷぺぽ/;
                    ($_, $c);
                }
                else {
                    $_;
                }
            } @chs;
            @chs = map {
                my $c = $_;
                $c =~ tr/ぁ-ゔ/ァ-ヴ/;
                ($_, $c);
            } @chs;
            if ($i != 0) {
                my $prev_ch = $chars[$i - 1];
                if ($prev_ch =~ m{[あかさたはなまわやわ]} and $ch eq 'あ' or
                    $prev_ch =~ m{[いきしちにひみり]} and $ch eq 'い' or
                    $prev_ch =~ m{[うくすつぬふむゆる]} and $ch eq 'う' or
                    $prev_ch =~ m{[えけせてねへめれ]} and $ch eq 'え' or
                    $prev_ch =~ m{[おこそとのほもよろを]} and $ch =~ m{^[おう]$}) {
                    push @chs, "";
                }
            }
            push @ambiguous_chars, "(?:".join("|", map { quotemeta $_ } @chs).")";
        }
        my $defaultsort_regexp = join('[\Wー]*', @ambiguous_chars).'ー?';

        $page =~ s{('''[^']+ ([\p{Hiragana}\p{Katakana}ー]+)'''[\W\p{Hiragana}\p{Katakana}ー]+ )-}{$1$2};
        $page =~ s{('''([\p{Hiragana}\p{Katakana}ー]+) [^']+'''\W+)-}{$1$2};
        
        while ($page =~ m{($name_regexp).*?[^\p{Hiragana}\p{Katakana}]($defaultsort_regexp)[^\p{Hiragana}\p{Katakana}ー]}g) {
            my $matched_name = $1;
            my $matched_kana = $2;
            my @split_name = split/\W+/, $matched_name;
            my @split_kana = split/\W+/, $matched_kana;
            if (scalar(@split_name) == 2 and scalar(@split_kana) == 2) {
                print join(" ", @split_name)."\t".join(" ", @split_kana)."\n";
                last;
            }
        }
    }
}
