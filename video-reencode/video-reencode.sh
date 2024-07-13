#!/bin/bash

echo "--------------"
echo "VIDEO REENCODE"
echo "--------------"
echo "Converts every video file in the current folder"
echo "(including the files in subfolders) to .mp4"
echo "with the specified settings. Deletes old files."
echo "Adds '.compressed.mp4' to the end of filenames."
echo

if ! which ffmpeg &> /dev/null
then
  echo "Install ffmpeg to continue."
  exit
fi

# change working dir to current dir
cd -- "$(dirname "$0")"

(
IFS=$'\n' # internal file separator for the for loop below 

echo "Choose a resolution:"
select RESOLUTION in "426x240" "640x360" "854x480" "1280x720" "1920x1080" "2560x1440" "3840x2160"; do
    break
done

echo "Choose a Compression Rate Factor CRF (recommended: 26)"
echo "(bigger number = more compression, smaller number = quality):"
select CRF in "30" "28" "26" "24" "22" "20"; do
    break
done

echo "Choose a FPS Frames Per Second value (recommended: 30):"
select FPS in "60" "30" "25" "24" "20" "15" "10" "5" "4" "2" "1"; do
    break
done

echo "Choose an audio bitrate:"
select ABITRATE in "32k" "48k" "64k" "96k" "128k" "160k" "192k" "256k" "320k"; do
    break
done

echo "Number of audio channels:"
select ACHANNELS in "1" "2"; do
    break
done

echo "Conversion speed (the faster the speed,"
echo "the larger the file size) (recommended: veryfast):"
select PRESET in "ultrafast" "superfast" "veryfast" "faster" "fast" "medium" "slow" "slower" "veryslow"; do
    break
done

echo "Number of CPU threads (FIRST OPTION 1): 0=auto ):"
select THREADS in "0" "1" "2" "4" "8" "16"; do
    break
done

FILES=$(find ./ -not -path '*/.*' \( -name "*.mp4" -o -name "*.MP4" -o -name "*.m4v" -o -name "*.M4V" -o -name "*.mkv" -o -name "*.MKV" -o -name "*.mpg" -o -name "*.MPG" -o -name "*.mpeg" -o -name "*.MPEG" -o -name "*.avi" -o -name "*.AVI" \) | sort -V)

# progress variables
NUMFILES=`echo "$FILES" | wc -l`
COUNTER=0

for file in $FILES
do
    # update progress
    ((COUNTER++))
    echo "-----------------"
    echo $NUMFILES "/" $COUNTER " " $((COUNTER * 100 / NUMFILES)) "% - " $file

    # skip if already compressed
    if echo "$file" | grep -q "\.compressed\.mp4"; then
        echo "SKIP"
        continue
    fi

    NEWFILENAME="$file".compressed.mp4

    ffmpeg -v error -stats -stats_period 1 -i "$file" -movflags +faststart -crf $CRF -preset $PRESET -s $RESOLUTION -r $FPS -threads $THREADS -vcodec libx264 -acodec aac -ar 44100 -ac $ACHANNELS -b:a $ABITRATE ./"$NEWFILENAME" -y && 
    rm "$file"
done
)
