extract_wp_names.pl
===================

What's this?
------------
This is a Perl script which extracts personal names (both their Kanji and Kana) in Japanese Wikipedia and output them in a form in which the family and given names are separated by a space.

How to use
----------
1. Get the Japanese Wikipedia dump file.
   curl -LO https://dumps.wikimedia.org/jawiki/latest/jawiki-latest-pages-articles.xml.bz2
2. Extract the file.
   bunzip2 ./jawiki-latest-pages-articles.xml.bz2
3. Run this script to extract personal names.
   cat ./jawiki-latest-pages-articles.xml | perl extract_jawp_names.pl

説明
----
日本語Wikipediaの人名（漢字・読み）を抽出し、姓と名がスペースで区切られた形で出力するPerlスクリプトです。

使い方
------
1. 日本語Wikipediaのファイルを取ってきます。
   curl -LO https://dumps.wikimedia.org/jawiki/latest/jawiki-latest-pages-articles.xml.bz2
2. ファイルを解凍します。
   bunzip2 ./jawiki-latest-pages-articles.xml.bz2
3. スクリプトを動かして人名を抽出します。
   cat ./jawiki-latest-pages-articles.xml | perl extract_jawp_names.pl

Expected Output/期待される出力
------------------------------
    士郎 正宗	しろう まさむね
    高橋 留美子	たかはし るみこ
    村上 もとか	むらかみ もとか
    青木 光恵	あおき みつえ
    赤塚 不二夫	あかつか ふじお
    一条 ゆかり	いちじょう ゆかり
    うすた 京介	うすた きょうすけ
    浦沢 直樹	うらさわ なおき
    車田 正美	くるまだ まさみ
    高橋 しん	たかはし しん
    ...
