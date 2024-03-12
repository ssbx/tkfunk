#!/bin/sh

rm -f all_colors.txt.tmp
for img in $(/bin/ls ximage*png); do
    convert $img -unique-colors -depth 32 txt:- >> all_colors.txt.tmp
done

cat all_colors.txt.tmp | grep -v ^# | cut -d " " -f 2 | sort -u > all_colors.txt
rm -f all_colors.txt.tmp
