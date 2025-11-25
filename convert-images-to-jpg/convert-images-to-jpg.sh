#!/bin/bash

# Convert exotic image formats to jpg.

# change working dir to current dir
cd -- "$(dirname "$0")"

if ! command -v convert &> /dev/null
then
	echo "imagemagick not found, installing..."
	brew install imagemagick
	sudo apt update && sudo apt install imagemagick -y
fi

(
IFS=$'\n'
for file in $(find . -type f \( -iname "*.png" -o -iname "*.webp" -o -iname "*.jfif" \
	                             -o -iname "*.cr2" -o -iname "*.heic" \))
do
	echo "$file"
	convert "$file" "$file".jpg \
		&& rm "$file"
done
)

echo "DONE, press ENTER to close"
read
