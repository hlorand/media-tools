#!/bin/bash

echo -e "------------------\nYouTube Downloader\n------------------"
echo "Downloads a YouTube video with yt-dlp at a user-specified"
echo "resolution and filename. Optionally trims the video."
echo ""

# check if URL provided
if [ -z "$1" ]; then
  echo "URL empty. Usage: $0 <Youtube.com URL with ?v= ending>"
  exit
fi

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

URL=$1

VIDEOID="${URL##*=}" # the part from url after = (wont work for urls that has multiple parameters)

echo "Choose a resolution:"
select RESOLUTION in "144" "240" "360" "480" "720" "1080" "1440" "2160"; do
    break
done

echo "Enter filename:"
read FILENAME
FILENAME="$FILENAME.$VIDEOID.mp4"

# download mp4 with audio
yt-dlp -f "bestvideo[height<=$RESOLUTION][vcodec=h264][ext=mp4]+bestaudio[ext=m4a]/best[height<=$RESOLUTION]" -o "$FILENAME" "$URL"

echo "Downloaded: $FILENAME"

echo -e "---------\nCUT VIDEO\n---------"

echo "Do you want to cut the video? (y/n): "
read answer

if [[ "$answer" == y* ]]; then

  echo "Enter start timecode (HH:MM:SS):"
  read START

  echo "Enter end timecode (HH:MM:SS):"
  read END

  ffmpeg -i "$FILENAME" -ss $START -to $END -c:v copy -c:a copy "$FILENAME.cut.mp4"

  echo "Trimmed video: $FILENAME.cut.mp4"

fi



