#!/bin/bash

# Check if two arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_video> <speed_percentage>"
    exit 1
fi

# Input arguments
INPUT_VIDEO=$1
SPEED_PERCENTAGE=$2

# Calculate speed factor
SPEED_FACTOR=$(echo "scale=2; $SPEED_PERCENTAGE / 100" | bc)

# Ensure speed factor is valid
if (( $(echo "$SPEED_FACTOR <= 0" | bc -l) )); then
    echo "Error: Speed percentage must be greater than 0"
    exit 1
fi

# Generate output file name
OUTPUT_VIDEO="output_${SPEED_PERCENTAGE}percent.mp4"

# Adjust video and audio speed using FFmpeg
ffmpeg -i "$INPUT_VIDEO" \
    -filter_complex "[0:v]setpts=1/$SPEED_FACTOR*PTS[v];[0:a]atempo=$SPEED_FACTOR[a]" \
    -map "[v]" -map "[a]" \
    "$OUTPUT_VIDEO"

echo "Output saved to $OUTPUT_VIDEO"
