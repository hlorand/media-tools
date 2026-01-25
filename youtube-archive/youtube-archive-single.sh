#!/bin/bash
set -euo pipefail

cd -- "$(dirname "$0")"

# --- Auto-update yt-dlp (brew on macOS, apt on Debian/Ubuntu Linux) ---
os="$(uname -s)"

if [[ "$os" == "Darwin" ]]; then
  if command -v brew >/dev/null 2>&1; then
    brew update
    brew upgrade yt-dlp
  else
    echo "Homebrew not found (brew). Skipping yt-dlp auto-update."
  fi
elif [[ "$os" == "Linux" ]]; then
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install --only-upgrade -y yt-dlp
  else
    echo "apt-get not found. Skipping yt-dlp auto-update."
  fi
else
  echo "Unsupported OS ($os). Skipping yt-dlp auto-update."
fi
# --- End auto-update block ---

echo "Enter YouTube video URL:"
read -r URL

echo "Select browser for cookies:"
echo "1) Firefox"
echo "2) Chrome"
echo "3) None"
read -r browser_choice

cookie_option=()
case "$browser_choice" in
  1) cookie_option=(--cookies-from-browser firefox) ;;
  2) cookie_option=(--cookies-from-browser chrome) ;;
  3) cookie_option=() ;;
  *) echo "Invalid choice, no cookies will be used."; cookie_option=() ;;
esac

echo "Select video resolution to download (max height):"
echo "1) 144p"
echo "2) 240p"
echo "3) 360p"
echo "4) 480p"
echo "5) 720p"
echo "6) 1080p"
echo "7) 1440p (2K)"
echo "8) 2160p (4K)"
read -r resolution_choice

case "$resolution_choice" in
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

echo "Select output mode:"
echo "1) Maximum compatibility: MP4 (H.264 + AAC) [re-encode]"
echo "2) Smaller files: MP4 (H.265/HEVC + AAC) [re-encode]"
echo "3) Quick archive: Keep YouTube formats (fast; may be webm/mp4)"
read -r mode_choice

echo "Do you want to cut the video?"
echo "1) No"
echo "2) Yes (requires ffmpeg; will re-encode in mode 1 or 2)"
read -r cut_choice

download_sections=()
START=""
END=""
if [[ "$cut_choice" == "2" ]]; then
  echo "Enter start timecode (HH:MM:SS):"
  read -r START
  echo "Enter end timecode (HH:MM:SS) or 'inf' to cut until end:"
  read -r END

  # yt-dlp supports time ranges using --download-sections with a '*' prefix.
  download_sections=(--download-sections "*${START}-${END}")
fi

# Force max resolution AND always have audio (standard bv*+ba/b fallback).
fmt_option="bv*[height<=${res}]+ba/b[height<=${res}]/bv*+ba/b"

pp_opts=()
out_ext="mkv"
case "$mode_choice" in
  1)
    pp_opts+=(--recode-video mp4)
    pp_opts+=(--postprocessor-args "VideoConvertor:-c:v libx264 -pix_fmt yuv420p -profile:v high -c:a aac -b:a 160k")
    out_ext="mp4"
    ;;
  2)
    pp_opts+=(--recode-video mp4)
    pp_opts+=(--postprocessor-args "VideoConvertor:-c:v libx265 -pix_fmt yuv420p -tag:v hvc1 -c:a aac -b:a 128k")
    out_ext="mp4"
    ;;
  3)
    out_ext="mkv"
    pp_opts+=(--merge-output-format mkv)
    ;;
  *)
    echo "Invalid choice, defaulting to 3 (quick archive)."
    out_ext="mkv"
    pp_opts+=(--merge-output-format mkv)
    ;;
esac

# Enforce your requirement: cutting implies re-encode modes (1 or 2).
# (Cutting can sometimes be “stream copy”, but frame-accurate cuts often require re-encoding.)
if [[ "$cut_choice" == "2" ]] && [[ "$mode_choice" == "3" ]]; then
  echo "Cutting was requested, but mode 3 does not re-encode."
  echo "Re-run and choose mode 1 or 2 for cutting."
  exit 1
fi

out_template="%(upload_date>%Y-%m-%d)s-%(id)s-%(title)s.%(ext)s"
final_name="$(yt-dlp --get-filename -o "$out_template" "$URL")"
final_name="${final_name%.*}.${out_ext}"

cmd=(
  yt-dlp
  -f "$fmt_option"
  "${download_sections[@]}"
  "${pp_opts[@]}"
  --restrict-filenames
  --add-metadata
  --embed-subs
  "${cookie_option[@]}"
  -o "$out_template"
  "$URL"
)

"${cmd[@]}"

echo "$final_name"
