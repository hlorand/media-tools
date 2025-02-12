#!/bin/bash

DESCRIPTION="Converts video, and targets a specific file size, creating <filename>-compressed.mp4/webm"

# Check if the first and second arguments are provided
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo $DESCRIPTION
    echo "Usage: $0 <video file> <target filesize in KB(kilobytes)> <audio kbps (kbit/sec)>"
    echo "Example: $0 input.mp4 4000 64"
    exit 1
fi

INPUT="$1"
TARGETSIZEINKBYTES="$2"
TARGETSIZEINKBITS=$(($TARGETSIZEINKBYTES * 8 )) # 4000 kbyte = 32'000 kbit

DURATIONINSEC=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT")
echo "Duration: $DURATIONINSEC sec"

AUDIO_BITRATE_KBITPS="$3"
echo "Audio: $AUDIO_BITRATE_KBITPS kbps"
echo "Audio size: $(echo "scale=0; $AUDIO_BITRATE_KBITPS / 8 * $DURATIONINSEC / 1" | bc) kb"

VIDEO_BITRATE_KBITPS=$(echo "scale=0; ($TARGETSIZEINKBITS - $AUDIO_BITRATE_KBITPS * $DURATIONINSEC) / $DURATIONINSEC" | bc)
echo "Video: $VIDEO_BITRATE_KBITPS kbps"
echo "Video size: $(echo "scale=0; $VIDEO_BITRATE_KBITPS / 8 * $DURATIONINSEC / 1" | bc) kb"


if [ "$VIDEO_BITRATE_KBITPS" -le 0 ]; then
    echo "Error: Target size is too small for the specified audio bitrate and video duration."
    exit 1
fi

echo -e "\nChoose a codec:"
select option in "libx264 (mp4)" "libvpx (webm)"; do
    case $REPLY in
        1) CODEC="libx264"; EXTENSION="mp4";;
        2) CODEC="libvpx"; EXTENSION="webm";;
        *) echo "Invalid option. Please try again."; continue;;
    esac
    break
done

echo "Do you want to scale the video? (1 = no)"
select SCALE in "1" "0.75" "0.5" "0.25" "0.2" "0.1"; do
    break
done

echo "Enter Start timestamp in HH:MM:SS format:"
read START

echo "Enter End timestamp in HH:MM:SS format:"
read END

OUTPUT="$INPUT-compressed.$EXTENSION"

#-minrate ${VIDEO_BITRATE_KBITPS}k
# pass 1
ffmpeg -i "$INPUT" -ss $START -to $END -c:v $CODEC -vf "scale=iw*$SCALE:ih*$SCALE" -b:v ${VIDEO_BITRATE_KBITPS}k -maxrate ${VIDEO_BITRATE_KBITPS}k -bufsize $((VIDEO_BITRATE_KBITPS / 2))k -deadline best -cpu-used 1 -b:a ${AUDIO_BITRATE_KBITPS}k -pass 1 -f $EXTENSION /dev/null -y

# pass 2
ffmpeg -i "$INPUT" -ss $START -to $END -c:v $CODEC -vf "scale=iw*$SCALE:ih*$SCALE" -b:v ${VIDEO_BITRATE_KBITPS}k -maxrate ${VIDEO_BITRATE_KBITPS}k -bufsize $((VIDEO_BITRATE_KBITPS / 2))k -deadline best -cpu-used 1 -b:a ${AUDIO_BITRATE_KBITPS}k -pass 2 "$OUTPUT" -y

# remove log
rm -f ffmpeg2pass-*.log

# Get the final file size of the output video
ACTUAL_SIZE_KB=$(du -k "$OUTPUT" | cut -f1)  # Convert to KB

# Check if the file size exceeds the target size
if [ "$ACTUAL_SIZE_KB" -gt "$TARGETSIZEINKBYTES" ]; then
    SIZE_DIFF_KB=$(($ACTUAL_SIZE_KB - $TARGETSIZEINKBYTES))
    PERCENTAGE_DIFF=$(echo "scale=2; $SIZE_DIFF_KB / $TARGETSIZEINKBYTES * 100" | bc)
    echo "Warning: The output file size exceeds the target by $SIZE_DIFF_KB KB ($PERCENTAGE_DIFF%)."
    echo "Try to scale the video because it won’t fit into the target file size."
else
    echo "Conversion successful. The file size is within the target."
fi