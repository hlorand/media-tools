#!/bin/bash

echo -e "------------------\nYouTube Downloader\n------------------"
echo "Downloads multiple YouTube videos."
echo "URLs are provided in a text file, one per line."
echo ""

# Check if both parameters are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <path_to_list.txt> <resolution>"
    exit 1
fi

# Check if yt-dlp is installed
if ! command -v yt-dlp &> /dev/null
then
    echo "yt-dlp could not be found. Please install yt-dlp."
    exit 1
fi

# Read URLs from the provided list file
while read -r url; do
    echo "Downloading $url"
    # Download the video in the specified resolution with audio
    yt-dlp -f "bestvideo[height<=$2][ext=mp4]+bestaudio[ext=mp4]/bestvideo[height<=$2]+bestaudio/best[height<=$2]" --merge-output-format mp4 -o "%(title)s.%(ext)s" "$url"
done < "$1"

echo "Downloads completed."