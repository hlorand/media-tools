#!/bin/bash

# Removes EXIF metadata from files in the current directory including subdirectories.

# change working dir to current dir
cd -- "$(dirname "$0")"

(
IFS=$'\n'
for file in $(find . -type f)
do
	echo "$file"
	exiftool -all= -overwrite_original "$file"; 
done
)

echo "DONE, press ENTER to close"
read
