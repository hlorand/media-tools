#!/bin/bash

echo "Enter YouTube channel URL (e.g. https://www.youtube.com/@...):"
read channel_url

# Extract channel name by splitting on '@' and remove whitespace
channel_name="${channel_url##*@}"
channel_name="$(echo "$channel_name" | tr -d '[:space:]' | tr -d '\r\n')"
safe_channel_name=$(echo "$channel_name" | sed 's/[^a-zA-Z0-9_-]//g')

echo "Channel name detected: $safe_channel_name"

mkdir -p "$safe_channel_name"

# Select browser for cookies
echo "Select browser for cookies:"
echo "1) Firefox"
echo "2) Chrome"
echo "3) None"
read browser_choice

case $browser_choice in
  1) cookie_option="--cookies-from-browser firefox" ;;
  2) cookie_option="--cookies-from-browser chrome" ;;
  3) cookie_option="" ;;  # No cookies option
  *) echo "Invalid choice, no cookies will be used."; cookie_option="" ;;
esac

echo "Select video resolution to download:"
echo "1) 144p"
echo "2) 240p"
echo "3) 360p"
echo "4) 480p"
echo "5) 720p"
echo "6) 1080p"
echo "7) 1440p (2K)"
echo "8) 2160p (4K)"
read resolution_choice

case $resolution_choice in
  1) res=144 ;;
  2) res=240 ;;
  3) res=360 ;;
  4) res=480 ;;
  5) res=720 ;;
  6) res=1080 ;;
  7) res=1440 ;;
  8) res=2160 ;;
  *) echo "Invalid choice, defaulting to 240p"; res=240 ;;
esac

echo "Select video format:"
echo "1) mp4 (will transcode to selected codec)"
echo "2) webm (will transcode to selected codec)"
echo "3) mkv (will transcode to selected codec)"
echo "4) I don't care (download exactly what YouTube offers, no transcoding)"
read format_choice

if [[ "$format_choice" == "4" ]]; then
  echo "Selected 'I don't care' - downloading without transcoding, keeping YouTube original formats."
  transcoding="no"
  ext=""
else
  transcoding="yes"
  case $format_choice in
    1) ext="mp4" ;;
    2) ext="webm" ;;
    3) ext="mkv" ;;
    *) echo "Invalid choice, defaulting to mp4"; ext="mp4" ;;
  esac
fi

if [[ "$transcoding" == "yes" ]]; then
  # Ask codec depending on container
  case $ext in
    mp4)
      echo "Select codec for mp4:"
      echo "1) h264 (recommended, most compatible)"
      echo "2) h265 (better compression, less compatible)"
      read codec_choice
      case $codec_choice in
        1) vcodec="avc1" ;;   # H264
        2) vcodec="hev1" ;;   # H265 (HEVC)
        *) echo "Invalid choice, defaulting to h264"; vcodec="avc1" ;;
      esac
      ;;
    webm)
      echo "Select codec for webm:"
      echo "1) vp9 (default)"
      echo "2) av1 (better compression, slow encoding)"
      read codec_choice
      case $codec_choice in
        1) vcodec="vp9" ;;
        2) vcodec="av01" ;;
        *) echo "Invalid choice, defaulting to vp9"; vcodec="vp9" ;;
      esac
      ;;
    mkv)
      echo "Select codec for mkv:"
      echo "1) h264"
      echo "2) h265"
      echo "3) vp9"
      read codec_choice
      case $codec_choice in
        1) vcodec="avc1" ;;
        2) vcodec="hev1" ;;
        3) vcodec="vp9" ;;
        *) echo "Invalid choice, defaulting to h264"; vcodec="avc1" ;;
      esac
      ;;
  esac
fi

echo "Starting download for channel $channel_url..."

current_date=$(date +%Y-%m-%d)

if [[ "$transcoding" == "yes" ]]; then
  # Force container and codec, transcoding if needed
  fmt_option="-f bv[height=${res}][ext=${ext}][vcodec^=${vcodec}]+ba/b[height=${res}][ext=${ext}][vcodec^=${vcodec}]"
  merge_format="$ext"
else
  # Download what YouTube offers without transcoding
  fmt_option=""
  merge_format="" # no merge-output-format to avoid transcoding
fi

yt-dlp $fmt_option \
  $( [[ "$transcoding" == "yes" ]] && echo "--merge-output-format $merge_format" ) \
  --download-archive "${safe_channel_name}/downloaded-${safe_channel_name}.txt" \
  --concurrent-fragments 1 \
  --throttled-rate 500K \
  --sleep-interval 5 \
  --max-sleep-interval 20 \
  --restrict-filenames \
  --add-metadata \
  --embed-subs \
  $cookie_option \
  --output-na-placeholder "$current_date-nodate-" \
  -o "${safe_channel_name}/%(upload_date>%Y-%m-%d)s-%(id)s-%(title)s.%(ext)s" \
  "$channel_url"

echo "Download completed! Files saved in folder: $safe_channel_name"
