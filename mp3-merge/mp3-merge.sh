#!/bin/bash

echo "--------------"
echo "MP3 MERGE"
echo "--------------"
echo "Merges every .mp3 file in the current folder"
echo "(NOT including the files in subfolders)"
echo "using ffmpeg into merged.mp3"
echo

# change working dir to current dir
cd -- "$(dirname "$0")"

# check ffmpeg installation
if ! which ffmpeg &> /dev/null
then
  echo "Install ffmpeg to continue."
  exit
fi

ffmpeg -i "concat:$(ls -1 *.mp3 | tr '\n' '|')" -acodec copy merged.mp3