#!/bin/bash

# YouTube Downloader
# Downloads a YouTube video with yt-dlp at a user-specified resolution.
# Echoes downloaded filename

# Check if the number of parameters is not equal to 2
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <Youtube.com URL> <resolution 144/240/360/480/720/1080/1440/2160/4320>"
  exit
fi

URL=$1
RES=$2

# check if yt-dlp installed
PROGRAM="yt-dlp"
if ! which $PROGRAM &> /dev/null
then
  echo "$PROGRAM could not be found, installing..."
  # linux
  sudo apt update &>/dev/null
  sudo apt install $program -y &>/dev/null
  # macos
  brew install yt-dlp &>/dev/null
fi

# download and get filename
echo "Downloading..." >&2
yt-dlp -f "bestvideo[height<=$RES][ext=mp4]+bestaudio" -o "%(title)s.%(ext)s" "$URL" &>/dev/null

FILENAME=$(yt-dlp -o '%(title)s.%(ext)s' --get-filename "$URL" 2>/dev/null)

echo $FILENAME
