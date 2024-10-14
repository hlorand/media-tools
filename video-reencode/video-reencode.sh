#!/bin/bash

echo -e "--------------\nVIDEO REENCODE\n--------------"
echo "Converts every video file in the current folder"
echo "(including the files in subfolders) to H264 .mp4"
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

echo -e "--------------\nVIDEO SETTINGS\n--------------"

echo "Choose a video codec:"
select CODEC in "libx264" "libx265"; do
    break
done

echo "Choose a resolution:"
select RESOLUTION in "original" "426x240" "640x360" "854x480" "1280x720" "1920x1080" "2560x1440" "3840x2160"; do
    break
done

echo "Choose a Compression Rate Factor CRF (recommended: 23 for h264 = 28 for h265 )"
echo "(bigger number = more compression, smaller number = quality):"
select CRF in "30" "28" "26" "24" "22" "20"; do
    break
done

echo "Choose a FPS Frames Per Second value (recommended: 30):"
select FPS in "60" "50" "30" "25" "24" "20" "15" "10" "5" "4" "2" "1"; do
    break
done

echo "Choose a video tune setting (film=everyday videos, stillimage=presentations"
echo "grain=old grainy videos, fastdecode=fast playback on low-performance devices"
echo "zerolatency=fast ENCODE for streaming, psnr/ssim=maximize these quality scores)"
CODEC_TUNES=("none" "film" "animation" "stillimage" "grain" "fastdecode" "zerolatency")
if [[ $CODEC == "libx265" ]]
then
    CODEC_TUNES=("none" "animation" "grain" "fastdecode" "zerolatency" "psnr" "ssim")
fi

select TUNE in "${CODEC_TUNES[@]}"; do
    break
done
if [[ $TUNE == "none" ]]
then
    TUNE=""
fi

echo -e "--------------\nAUDIO SETTINGS\n--------------"

echo "Number of audio channels:"
select ACHANNELS in "2" "1" "0"; do
    break
done

if [ $ACHANNELS -ne 0 ]
then
    echo "Choose an audio bitrate:"
    select ABITRATE in "32k" "48k" "64k" "96k" "128k" "160k" "192k" "256k" "320k"; do
        break
    done
fi

echo -e "--------------\nCONVERSION SETTINGS\n--------------"

echo "Conversion speed (the faster the speed,"
echo "the larger the file size) (recommended: veryfast):"
select PRESET in "ultrafast" "superfast" "veryfast" "faster" "fast" "medium" "slow" "slower" "veryslow"; do
    break
done

echo "Number of CPU threads (FIRST OPTION 1): 0=auto ):"
select THREADS in "0" "1" "2" "4" "8" "16"; do
    break
done

##########################################

FILES=$(find ./ -not -path '*/.*' \( -name "*.mp4" -o -name "*.MP4" -o -name "*.m4v" -o -name "*.M4V" -o -name "*.mkv" -o -name "*.MKV" -o -name "*.mpg" -o -name "*.MPG" -o -name "*.mpeg" -o -name "*.MPEG" -o -name "*.avi" -o -name "*.AVI" -o -name "*.mov" -o -name "*.MOV" \) | sort -V)

# progress variables
NUMFILES=`echo "$FILES" | wc -l`
COUNTER=0

SIZEBEFORE=$(du -sh | cut -d$'\t' -f1)

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

    # Check if the file contains an apostrophe, if so then rename
    if [[ "$file" == *"'"* ]]; then
      new_filename=$(echo "$file" | tr -d "'")  # remove apostrophe

      mv "$file" "$new_filename"
      file=$new_filename
    fi

    # Get resolution
    DIMENSIONS=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$file")
    width=$(echo "$DIMENSIONS" | cut -d'x' -f1)
    height=$(echo "$DIMENSIONS" | cut -d'x' -f2)

    if [[ $RESOLUTION != "original" ]]
    then
        # Detect orientation, swap widh and height if vertical video
        if [ "$width" -lt "$height" ]; then
            targetwidth=$(echo "$RESOLUTION" | cut -d'x' -f1)
            targetheight=$(echo "$RESOLUTION" | cut -d'x' -f2)
            DIMENSIONS=$targetheight"x"$targetwidth
        else
            DIMENSIONS=$RESOLUTION
        fi
    fi


    NEWFILENAME="$file".compressed.mp4

    # set audio options based by channel count
    AUDIO_OPTIONS=()
    if [[ "$ACHANNELS" == "0" ]]; then
        AUDIO_OPTIONS+=("-an")
    else
        AUDIO_OPTIONS+=("-acodec" "aac" "-ar" "44100" "-ac" "$ACHANNELS" "-b:a" "$ABITRATE")
    fi

    ffmpeg -v error -stats -stats_period 1 -i "$file" -movflags +faststart \
            -crf "$CRF" \
            -preset "$PRESET" \
            -s "$DIMENSIONS" \
            -r "$FPS" \
            -threads "$THREADS" \
            ${TUNE:+"-tune"} ${TUNE:+"$TUNE"} \
            -vcodec $CODEC \
            "${AUDIO_OPTIONS[@]}" \
            ./"$NEWFILENAME" -y &&
    rm "$file"
done

echo -e "\nSize before: " $SIZEBEFORE
echo "Size after: " $(du -sh | cut -d$'\t' -f1)
echo "Press ENTER to exit"; read enter
)
