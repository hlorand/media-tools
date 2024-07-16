#!/bin/bash

echo "--------------"
echo "MP4 MERGE"
echo "--------------"
echo "Finds every MP4 file in subfolders and merges them into a single .mp4 file."
echo "Filename: Parent folder name.mp4"
echo "Creates chapters for the merged video. Certain media players can use this information."
echo "For example: In VLC, go to Playback menu > Chapters > Jump to chapter."
echo

# check ffmpeg installation
if ! which ffmpeg &> /dev/null
then
  echo "Install ffmpeg to continue."
  exit
fi

# change working dir to current dir
cd -- "$(dirname "$0")"

# clear possible previous run files
rm files-to-merge.txt chapters.txt &>/dev/null

(
IFS=$'\n' # internal file separator for the for loop below 

timestamp=0 # timestamp for chapters

# -V version sort, use -h to human sort
for file in $(find . -not -path '*/.*' -name "*.mp4" -o -name "*.MP4" | sort -V)
do
    # Check if the file contains an apostrophe, if so then rename
    if [[ "$file" == *"'"* ]]; then
      new_filename=$(echo "$file" | tr -d "'")  # remove apostrophe

      mv "$file" "$new_filename"
      file=$new_filename
    fi

    echo "file '$file'" >> files-to-merge.txt
    echo $file

    # video length in sec, ffprobe: get length in 123.456 format, awk: multiply by 1000 to get millisec and round to int
    length=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $file | awk '{printf "%.0f\n", $1 * 1000}')

    # generate chapter file
    # https://ikyle.me/blog/2020/add-mp4-chapters-ffmpeg
    echo "[CHAPTER]" >> chapters.txt
    echo "TIMEBASE=1/1000" >> chapters.txt
    echo "START=$timestamp" >> chapters.txt
    timestamp=$((timestamp + length))
    echo "END=$timestamp" >> chapters.txt
    file="${file/.compressed.mp4/}" # remove ".comressed.mp4"
    file="${file/.\//}" # remove "./"
    echo "title='$file'" >> chapters.txt
    echo "" >> chapters.txt
done

read -p "ORDER OK? ENTER TO CONTINUE" enter

# get parent folder name (use this for filename)
script_path=$(realpath "$0")
script_dir=$(dirname "$script_path")
current_folder_name=$(basename "$script_dir")

# merge
ffmpeg -f concat -safe 0 -i files-to-merge.txt -c copy "$current_folder_name.mp4" &&

# add chapters (1. get current metadata to meta.txt | 2. merge with chapter file | 3. write metadata to new mp4)
ffmpeg -i "$current_folder_name.mp4" -f ffmetadata meta.txt &&
cat chapters.txt >> meta.txt &&
ffmpeg -i "$current_folder_name.mp4" -i meta.txt -map_metadata 1 -codec copy "$current_folder_name-meta.mp4" &&

# clean
rm chapters.txt meta.txt files-to-merge.txt "$current_folder_name.mp4"
mv "$current_folder_name-meta.mp4" "$current_folder_name.mp4"
)
