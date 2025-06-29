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

####################
# print timestamps

cumulative_seconds=0

for file in *.mp3; do
  # Get duration using ffprobe (rounds to integer seconds)
  duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file")
  
  # Calculate timestamp components
  hours=$((cumulative_seconds / 3600))
  minutes=$(((cumulative_seconds % 3600) / 60))
  seconds=$((cumulative_seconds % 60))
  
  # Print formatted timestamp and filename
  printf "%02d:%02d:%02d %s\n" $hours $minutes $seconds "$file"
  
  # Update cumulative time (truncate decimal duration)
  cumulative_seconds=$((cumulative_seconds + ${duration%.*}))
done
