#!/bin/bash

echo -e "----------\nMP3 to MP4\n----------"
echo "Converts mp3 file to mp4 video using the provided image file"

# Check if both parameters are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <mp3 file> <image file>"
    exit
fi

# Check if ffmpeg is installed
if ! which ffmpeg &> /dev/null; then
    echo "Install ffmpeg to continue"
    exit
fi

MP3=$1
IMAGE=$2

ffmpeg -loop 1 -i "$IMAGE" -i "$MP3" -r 1 -preset ultrafast -c:a copy -c:v libx264 -shortest "$MP3.mp4" -y