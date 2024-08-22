#!/bin/bash

# Finds every media file based on file header bytes
# https://gist.github.com/leommoore/f9e57ba2aa4bf197ebc5
# https://en.wikipedia.org/wiki/List_of_file_signatures

# change dir to current dir
cd -- $(dirname $0)

# header bytes in hexacedimal
jpg="ffd8ffe0|ffd8ffe1|ffd8ffdb|ffd8ffee"
png="89504e47"
gif="47494638"
tif="4d4d002a|49492a00"
webp="52494646"

mp4="6674797069736f6d|667479704d534e56"
mkv_webm="1a45dfa3"
avi="52494646"
mpg="000001b3"

(
IFS=$'\n'

for file in $(find . -type f)
do
    # hexdump first 8 bytes and regex search for string
    xxd -len 8 -plain $file | grep -E "$jpg|$png|$gif|$tif|$webp|$mp4|$mkv_webm|$avi|$mpg" &>/dev/null
    if [ $? -eq 0 ]
    then
        echo $file
    fi
done
)

