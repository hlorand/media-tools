#!/bin/bash

echo -e "-------------\nMEDIA TO EXIF DATETIME\n-------------"
echo "Renames all media files in the current folder and subfolders"
echo "to the EXIF date and time in this format: YYYY-MM-DD HH-MM-SS STRING.EXT"
echo ""

echo "Do you want to add extra string after date/time? (y/n)"
read answer
if [[ "$answer" == y* ]]
then
	echo "Enter string:"
	read string
	string=" $string" # add space
fi

# Ellenőrzés, hogy exiftool telepítve van-e, ha nincs telepítés.
if ! command -v exiftool &>/dev/null
then
	echo "exiftool not found, installing..."
	brew install exiftool &>/dev/null
	sudo apt update &>/dev/null
	sudo apt install exiftool -y &>/dev/null
fi

# change working dir to current dir
cd -- "$(dirname "$0")"

(
IFS=$'\n' # internal file separator for the for loop below 

for filename in $(find . -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.heic" -o -iname "*.cr2" -o -iname "*.png" -o -iname "*.jfif" -o -iname "*.mov" -o -iname "*.mp4" -o -iname "*.m4v" -o -iname "*.mod" -o -iname "*.mpo" -o -iname "*.mpg" -o -iname "*.mpeg" -o -iname "*.avi" \))
do
	# Requesting EXIF date with exiftool. s3: short, only value, m: skip minor problems.
	datetime=$(exiftool -m -s3 -DateTimeOriginal "$filename")

	# If EXIF date is not set, we take the existing file date in order:
  	# Creation date, if that's not set either, then Modification date.
  	if [ "$datetime" = "" ] || [ "$datetime" = "0000:00:00 00:00:00" ]
	then
		datetime=$(exiftool -s3 -GPSDateTime "$filename")
	fi
	if [ "$datetime" = "" ] || [ "$datetime" = "0000:00:00 00:00:00" ]
	then
		datetime=$(exiftool -s3 -CreateDate "$filename")
	fi
	if [ "$datetime" = "" ] || [ "$datetime" = "0000:00:00 00:00:00" ]
	then
		datetime=$(exiftool -s3 -FileModifyDate "$filename")
	fi

	# Get extension and make it lowercase https://stackoverflow.com/a/965072/5380098
	extension=${filename##*.}
	extension=$(echo $extension | tr '[:upper:]' '[:lower:]')

	# exiftool sometimes provides dates more precisely than seconds, deleting them from the end
	# (e.g. 2022:11:29 13:14:15+1:00 or 2022:11:29 13:14:15-1:00)"
	datetime=$(echo $datetime | cut -f1 -d"-" | cut -f1 -d"+")

	# Transforming colon into hyphen
	datetime=$(echo $datetime | tr ':' '-')

	# New filename format
	newfilename="$datetime$string.$extension"

	# Avoiding collisions: as long as there exists a file with the same name but different content,
	# we add a counter to the file name until it's unique
	cnt=1
	while [[ -f $newfilename ]] && [[ $(crc32 $filename) != $(crc32 $newfilename) ]]
	do
		echo $filename "===" $newfilename "EXISTS"
		newfilename=$directory"/"$datetime"."$cnt"."$extension
		echo $filename "-->" $newfilename "RENAMED"
		((cnt=cnt+1))
	done

	# Rename file
	echo $filename "-->" $newfilename
	mv $filename $newfilename

done
)

echo "DONE"
read enter
