#!/bin/bash

echo -e "--------------\nAUDIO REENCODE\n--------------"
echo "Converts every audio file in the current folder"
echo "(including the files in subfolders) to the selected"
echo "audio format."
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

echo "Choose an audio codec (mp3, ogg, aac, opus):"
select ACODEC in "libmp3lame" "libvorbis" "libfdk_aac" "libopus"; do
    break
done

echo "Choose a bitrate:"
select ABITRATE in "8k" "12k" "16k" "24k" "32k" "48k" "64k" "96k" "128k" "192k" "256k" "320k"; do
    break
done

echo "Number of audio channels:"
select ACHANNELS in "1" "2" "0"; do
    break
done

echo "Number of CPU threads (FIRST OPTION 1): 0=auto ):"
select THREADS in "0" "1" "2" "4" "8" "16"; do
    break
done

echo "Do you want to delete original files after conversion?"
select DELETE in "yes" "no"; do
    break
done

##########################################

FILES=$(find ./ -not -path '*/.*' \( -name "*.mp3" -o -name "*.MP3" -o -name "*.ogg" -o -name "*.OGG" -o -name "*.m4a" -o -name "*.M4A" -o -name "*.wav" -o -name "*.WAV" -o -name "*.wma" -o -name "*.WMA" -o -name "*.flac" -o -name "*.FLAC" -o -name "*.amr" -o -name "*.AMR" \) | sort -V)

for file in $FILES
do
    # skip if already compressed
    if echo "$file" | grep -q "\.compressed\."; then
        echo "SKIP"
        continue
    fi

    # Check if the file contains an apostrophe, if so then rename
    if [[ "$file" == *"'"* ]]; then
      new_filename=$(echo "$file" | tr -d "'")  # remove apostrophe

      mv "$file" "$new_filename"
      file=$new_filename
    fi

     
    # aac_he_v2: tailored fo low bitrate audio, csak stereo, legkisebb 32kbps
    ffmpeg -i input.mp3 -c:a libopus -b:a 16k -ac 1 output.opus

    if [ "$ACODEC" = "libmp3lame" ]; then
        ffmpeg -i "$file" -c:a "$ACODEC" -b:a "$ABITRATE" -ac "$ACHANNELS" "$file.compressed.mp3" -y;
    elif [ "$ACODEC" = "libvorbis" ]; then
        ffmpeg -i "$file" -c:a "$ACODEC" -b:a "$ABITRATE" -ac "$ACHANNELS" "$file.compressed.ogg" -y;
    elif [ "$ACODEC" = "libfdk_aac" ]; then
        ffmpeg -i "$file" -c:a libfdk_aac -profile:a aac_he_v2 -b:a "$ABITRATE" -ac "$ACHANNELS" -vn "$file.compressed.m4a" -y;
    elif [ "$ACODEC" = "libopus" ]; then
        ffmpeg -i "$file" -c:a "$ACODEC" -b:a "$ABITRATE" -ac "$ACHANNELS" "$file.compressed.ogg" -y;
    fi

    if [ "$DELETE" = "yes" ]; then
        rm "$file"
    fi
done

echo "Press ENTER to exit"; read enter
)
