#!/bin/bash

echo -e "--------------\nVIDEO REENCODE\n--------------"
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

echo -e "--------------\nVIDEO SETTINGS\n--------------"

echo "Choose a video codec:"
select CODEC in "libx264" "libx265" "libaom-av1"; do
    break
done

echo "Choose a resolution:"
select RESOLUTION in "original" "426x240" "640x360" "854x480" "1280x720" "1920x1080" "2560x1440" "3840x2160"; do
    break
done

echo "Keep aspect ratio? (width forced, height auto"
select ASPECT in "yes" "no"; do
    break
done

echo "Do you want to scale the video? (1 = no)"
echo "If you scale, original resolution used."
select SCALE in "1" "0.75" "0.5" "0.25" "0.2" "0.1"; do
    break
done

echo "Do you want to rotate the video?"
echo "If you scale, original resolution used."
select ROTATE in "no" "+90" "-90" "180"; do
    break
done

echo "Do you want to flip the video?"
echo "If you scale, original resolution used."
select FLIP in "no" "horizontal" "vertical"; do
    break
done


echo "Choose a Compression Rate Factor CRF (recommended: 23 for h264 = 28 for h265 )"
echo "(bigger number = more compression, smaller number = quality):"
select CRF in "40" "38" "36" "34" "32" "30" "28" "26" "24" "22" "20" "18"; do
    break
done

echo "Choose a FPS Frames Per Second value (recommended: 30):"
select FPS in "original" "60" "50" "30" "25" "24" "20" "15" "10" "6" "5" "4" "3" "2" "1"; do
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

echo "Choose a color space (SDR for H.264, HDR for H.265; some players can use HDR with H.264 too):"
echo "Use SDR (8‑bit), Rec.709 gamut, SDR curve: for everyday viewing."
echo "Use HDR (10‑bit), Rec.2020 gamut, HLG (Hybrid Log‑Gamma) curve: if you watch on both SDR and HDR screens."
echo "Use HDR (10‑bit), Rec.2020 gamut, PQ (ST 2084) curve: if you only watch on fully HDR‑compatible screens."
echo "   (If HDR has extra Dolby Vision metadata, ffmpeg cannot keep it; it will be stripped.)"
select COLORSPACE in "SDR_Rec709" "HDR_HLG_Rec2020" "HDR10_PQ_Rec2020"; do
    break
done

COLORSPACE_OPTIONS=()
case "$COLORSPACE" in
  "SDR_Rec709")
    COLORSPACE_OPTIONS+=(
      "-color_primaries" "bt709"
      "-color_trc" "bt709"
      "-colorspace" "bt709"
    )
    ;;
  "HDR_HLG_Rec2020")
    COLORSPACE_OPTIONS+=(
      "-color_primaries" "bt2020"
      "-color_trc" "arib-std-b67"
      "-colorspace" "bt2020nc"
    )
    ;;
  "HDR10_PQ_Rec2020")
    COLORSPACE_OPTIONS+=(
      "-color_primaries" "bt2020"
      "-color_trc" "smpte2084"
      "-colorspace" "bt2020nc"
    )
    ;;
esac


echo -e "--------------\nAUDIO SETTINGS\n--------------"

echo "Number of audio channels:"
select ACHANNELS in "1" "2" "0"; do
    break
done

if [ $ACHANNELS -ne 0 ]
then
    echo "Choose an audio bitrate:"
    select ABITRATE in "32k" "48k" "64k" "96k" "128k" "160k" "192k" "256k" "320k"; do
        break
    done
fi

echo "Trim video?"
select TRIM in "no" "yes"; do
  break
done

echo -e "--------------\nOPTIONAL TRIM\n--------------"

TRIM_FROM=""
TRIM_TO=""

if [[ "$TRIM" == "yes" ]]; then
  read -r -p "From timecode (HH:MM:SS): " TRIM_FROM
  read -r -p "To timecode   (HH:MM:SS): " TRIM_TO

  # Minimal format check (00-99 hours allowed)
  if [[ ! "$TRIM_FROM" =~ ^[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]] || [[ ! "$TRIM_TO" =~ ^[0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
    echo "Invalid timecode format. Use HH:MM:SS (example: 00:01:23)."
    exit 1
  fi
fi

TRIM_OPTIONS=()
if [[ "$TRIM" == "yes" ]]; then
  # Put after -i for more accurate trimming when encoding
  TRIM_OPTIONS+=( -ss "$TRIM_FROM" -to "$TRIM_TO" )
fi

TRIM_SUFFIX=""
if [[ "$TRIM" == "yes" ]]; then
  FROM_SAFE="${TRIM_FROM//:/-}"
  TO_SAFE="${TRIM_TO//:/-}"
  TRIM_SUFFIX=".from${FROM_SAFE}.to${TO_SAFE}"
fi


echo -e "--------------\nCONVERSION SETTINGS\n--------------"

echo "Conversion speed (the faster the speed, the larger the file size)"
echo "(optimal choice: h264:medium, h265:fast)"
echo "(smallest filesize: h264:veryfast, h265:superfast)"
select PRESET in "ultrafast" "superfast" "veryfast" "faster" "fast" "medium" "slow" "slower" "veryslow"; do
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

FILES=$(find ./ -not -path '*/.*' \( -name "*.mp4" -o -name "*.MP4" -o -name "*.m4v" -o -name "*.M4V" -o -name "*.mkv" -o -name "*.MKV" -o -name "*.mpg" -o -name "*.MPG" -o -name "*.mpeg" -o -name "*.MPEG" -o -name "*.avi" -o -name "*.AVI" -o -name "*.mov" -o -name "*.MOV" -o -name "*.ts" -o -name "*.TS" \) | sort -V)

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
    if echo "$file" | grep -q "\.compressed\.m"; then
        echo "SKIP"
        continue
    fi

    # Check if the file contains an apostrophe, if so then rename
    if [[ "$file" == *"'"* ]]; then
      new_filename=$(echo "$file" | tr -d "'")  # remove apostrophe

      mv "$file" "$new_filename"
      file=$new_filename
    fi

    # Get current dimensions
    DIMENSIONS=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$file")
    width=$(echo "$DIMENSIONS" | cut -d'x' -f1)
    height=$(echo "$DIMENSIONS" | cut -d'x' -f2)

    # target resolution, replace x with : to make it work in -vf video filter options
    RESOLUTION="${RESOLUTION/x/:}"

    if [[ $RESOLUTION != "original" ]]; then
        # Detect orientation, swap widh and height if vertical video
        if [ "$width" -lt "$height" ]; then
            targetwidth=$(echo "$RESOLUTION" | cut -d':' -f1)
            targetheight=$(echo "$RESOLUTION" | cut -d':' -f2)
            DIMENSIONS=$targetheight":"$targetwidth
        else
            DIMENSIONS=$RESOLUTION
        fi
    else
        DIMENSIONS=$width":"$height
    fi
    
    # to keep original fps, we just omit -r argument, else we use it
    FPS_OPTIONS=()
    if [[ $FPS != "original" ]]
    then
        FPS_OPTIONS+=("-r" "$FPS")
    fi

    # set extension, AV1 codec requires .mkv container
    EXTENSION="mp4"
    if [[ $CODEC == "libaom-av1" ]]
    then
        EXTENSION="mkv"
    fi

    RES="${RESOLUTION/:/x}"; # windows filename compatible resolution string with x separator 
    NEWFILENAME="$file".crf$CRF.$FPS"fps".$RES.scale$SCALE.$CODEC.$COLORSPACE"$TRIM_SUFFIX".compressed.$EXTENSION

    # set audio options based on channel count
    AUDIO_OPTIONS=()
    if [[ "$ACHANNELS" == "0" ]]; then
        AUDIO_OPTIONS+=("-an")
    else
        AUDIO_OPTIONS+=("-acodec" "aac" "-ar" "44100" "-ac" "$ACHANNELS" "-b:a" "$ABITRATE")
    fi

    # if keep aspect: fix width, auto height. -2 => auto height, but ensure value divisible by 2
    if [[ "$ASPECT" == "yes" ]]; then
        targetwidth=$(echo "$DIMENSIONS" | cut -d':' -f1)
        DIMENSIONS="$targetwidth:-2"
    fi

    # optional scale filter
    VIDEO_FILTERS=()
    if [[ "$SCALE" != "1" ]]; then
        VIDEO_FILTERS+=("scale=trunc(iw*$SCALE/2)*2:trunc(ih*$SCALE/2)*2,setsar=1")
    else
        # apply scale with DIMENSIONS and then square pixels
        VIDEO_FILTERS+=("scale=$DIMENSIONS,setsar=1")
    fi

    # optional rotation filter
    if [[ "$ROTATE" == "+90" ]]; then
        VIDEO_FILTERS+=("transpose=1")
    elif [[ "$ROTATE" == "-90" ]]; then
        VIDEO_FILTERS+=("transpose=2")
    elif [[ "$ROTATE" == "180" ]]; then
        VIDEO_FILTERS+=("transpose=1" "transpose=1")
    fi

    # optional flip filter
    if [[ "$FLIP" == "horizontal" ]]; then
        VIDEO_FILTERS+=("hflip")
    elif [[ "$FLIP" == "vertical" ]]; then
        VIDEO_FILTERS+=("vflip")
    fi

    # Join VIDEO_FILTERS into a comma-separated string and add -vf
    if [[ ${#VIDEO_FILTERS[@]} -gt 0 ]]; then
        VIDEO_FILTERS_STR=$(IFS=,; echo "${VIDEO_FILTERS[*]}")
        VIDEO_FILTERS=("-vf" "$VIDEO_FILTERS_STR")
    fi

    # function to display command before execution
    echo_cmd() {
        echo "-----------"
        echo "$@"
        echo "-----------"
        "$@"
    }

    echo_cmd ffmpeg -v error -stats -stats_period 1 \
            -i "$file" \
            "${TRIM_OPTIONS[@]}" \
            -movflags +faststart \
            -crf "$CRF" \
            -preset "$PRESET" \
            "${VIDEO_FILTERS[@]}" \
            "${FPS_OPTIONS[@]}" \
            "${COLORSPACE_OPTIONS[@]}" \
            -threads "$THREADS" \
            ${TUNE:+"-tune"} ${TUNE:+"$TUNE"} \
            -vcodec $CODEC \
            "${AUDIO_OPTIONS[@]}" \
            ./"$NEWFILENAME" -y &&
    [ "$DELETE" = "yes" ] && rm "$file"
done

echo -e "\nSize before: " $SIZEBEFORE
echo "Size after: " $(du -sh | cut -d$'\t' -f1)
echo "Press ENTER to exit"; read enter
echo -e "\\a\\a\\a" # bell 
)
