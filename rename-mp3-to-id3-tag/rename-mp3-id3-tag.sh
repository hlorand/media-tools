#!/bin/bash

# Find all .mp3 files in the current directory and its subdirectories
find . -type f -name "*.mp3" | while IFS= read -r FILE; do
    # Extract metadata using ffprobe
    artist=$(ffprobe -loglevel error -show_entries format_tags=artist -of default=noprint_wrappers=1:nokey=1 "$FILE" | sed 's/ *- */ /g')
    album=$(ffprobe -loglevel error -show_entries format_tags=album -of default=noprint_wrappers=1:nokey=1 "$FILE" | sed 's/ *- */ /g')
    year=$(ffprobe -loglevel error -show_entries format_tags=date -of default=noprint_wrappers=1:nokey=1 "$FILE" | sed 's/ *- */ /g')
    title=$(ffprobe -loglevel error -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 "$FILE" | sed 's/ *- */ /g')

    # Construct the new filename
    NEWFILENAME="$artist - $year - $album - $title.mp3"

    # Replace `/` and `,` with `+`
    NEWFILENAME="${NEWFILENAME//[\/,]/ + }"

    # Replace `&` with `and`
    NEWFILENAME="${NEWFILENAME//&/and}"

    # Remove special characters except spaces, hyphens, and plus signs
    NEWFILENAME=$(echo "$NEWFILENAME" | tr -dc '[:alnum:] \-+.')

    # Rename the file
    echo "$FILE --> $NEWFILENAME"
    mv "$FILE" "$(dirname "$FILE")/$NEWFILENAME"
done
