#!/bin/bash
set -euo pipefail

# --- Auto-update yt-dlp (brew on macOS, apt on Debian/Ubuntu Linux) ---
os="$(uname -s)"  # Darwin on macOS, Linux on Linux.

if [[ "$os" == "Darwin" ]]; then
  if command -v brew >/dev/null 2>&1; then
    brew update
    brew upgrade yt-dlp  # update yt-dlp via Homebrew. [web:86]
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

echo "Enter YouTube channel URL (e.g. https://www.youtube.com/@...):"
read -r channel_url

channel_name="${channel_url##*@}"
channel_name="$(echo "$channel_name" | tr -d '[:space:]' | tr -d '\r\n')"
safe_channel_name="$(echo "$channel_name" | sed 's/[^a-zA-Z0-9_-]//g')"

echo "Channel name detected: $safe_channel_name"
mkdir -p "$safe_channel_name"

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

echo "Rate limit (KB/s). Enter 0 for unlimited:"
read -r rate_kbps

echo "Min sleep seconds between downloads (e.g. 5). Enter 0 for no sleep:"
read -r min_sleep

echo "Max sleep seconds between downloads (randomized). Enter 0 to disable max sleep:"
read -r max_sleep

# Rate limit option: use -r/--limit-rate to actually cap bandwidth.
rate_option=()
if [[ "${rate_kbps:-0}" =~ ^[0-9]+$ ]] && [[ "$rate_kbps" -gt 0 ]]; then
  rate_option=(-r "${rate_kbps}K")
fi

# Sleep options: --sleep-interval and --max-sleep-interval.
sleep_options=()
if [[ "${min_sleep:-0}" =~ ^[0-9]+(\.[0-9]+)?$ ]] && [[ "$(printf "%.0f" "$min_sleep")" -gt 0 ]]; then
  sleep_options+=(--sleep-interval "$min_sleep")
  if [[ "${max_sleep:-0}" =~ ^[0-9]+(\.[0-9]+)?$ ]] && [[ "$(printf "%.0f" "$max_sleep")" -gt 0 ]]; then
    sleep_options+=(--max-sleep-interval "$max_sleep")
  fi
fi

# Force max resolution AND always have audio using bv*+ba/b fallback.
fmt_option="bv*[height<=${res}]+ba/b[height<=${res}]/bv*+ba/b"

# Post-processing options (kept as arrays to avoid quote issues).
pp_opts=()
case "$mode_choice" in
  1)
    # MP4/H.264/AAC for max compatibility (re-encode).
    pp_opts+=(--recode-video mp4)
    pp_opts+=(--postprocessor-args "VideoConvertor:-c:v libx264 -pix_fmt yuv420p -profile:v high -c:a aac -b:a 160k")
    ;;
  2)
    # MP4/H.265/AAC for smaller files (re-encode).
    pp_opts+=(--recode-video mp4)
    pp_opts+=(--postprocessor-args "VideoConvertor:-c:v libx265 -pix_fmt yuv420p -tag:v hvc1 -c:a aac -b:a 128k")
    ;;
  3)
    # Quick archive: no re-encode; merge into mkv when needed for mixed codecs.
    pp_opts+=(--merge-output-format mkv)
    ;;
  *)
    echo "Invalid choice, defaulting to 3 (quick archive)."
    pp_opts+=(--merge-output-format mkv)
    ;;
esac

current_date=$(date +%Y-%m-%d)

# Build yt-dlp command as an array to preserve argument boundaries (prevents "No closing quotation").
cmd=(
  yt-dlp
  -f "$fmt_option"
  "${pp_opts[@]}"
  "${rate_option[@]}"
  "${sleep_options[@]}"
  --download-archive "${safe_channel_name}/downloaded-${safe_channel_name}.txt"
  --concurrent-fragments 1
  --restrict-filenames
  --add-metadata
  --embed-subs
  "${cookie_option[@]}"
  --output-na-placeholder "$current_date-nodate-"
  -o "${safe_channel_name}/%(upload_date>%Y-%m-%d)s-%(id)s-%(title)s.%(ext)s"
  "$channel_url"
)

"${cmd[@]}"

echo "Download completed! Files saved in folder: $safe_channel_name"
