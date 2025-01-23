#!/bin/bash

# Compresses PDF using ImageMagick. Makes the PDF smaller in resolution and uses a grayscale palette.
# Usage: script.sh input.pdf
# Settings below:

PAGERESOLUTION=1000 # pixels
NUMCOLORS=16        # must be <= bitdepth^2
BITDEPTH=4          # must be power of 2: 2,4,8...
COLORS="sRGB"       # "Gray" (better for texts) or "sRGB"

# Validate input
if [ -z "$1" ] || [ ! -f "$1" ]; then
    echo "Usage: $0 input.pdf"
    exit 1
fi

# Install ImageMagick if not present
if ! command -v magick &> /dev/null; then
    echo "ImageMagick not installed. Install: brew install imagemagick || apt install imagemagick"
    exit 1
fi

mkdir -p jpg
cd jpg

# Convert input file to JPG
echo "Converting to JPGs"
magick "../$1" -density 300 -quality 90 output-%04d.jpg &

pid=$! # Get the PID of the last background process
while true; do
  if ps -p $pid > /dev/null 2>&1; then
    cpu=$(ps -p $pid -o %cpu=)
    mem=$(ps -p $pid -o %mem=)
    printf "\rCPU: %s%%, Memory: %s%%" "$cpu" "$mem"
  else
    break
  fi
  sleep 1
done

# Create GIF directory
mkdir -p gif

# Convert JPG to GIF
echo -e "\nConverting to GIFs"
for f in *.jpg; do 
    magick "$f" -resize x$PAGERESOLUTION -colorspace $COLORS -colors $NUMCOLORS +dither -depth $BITDEPTH -strip "gif/${f%.jpg}.gif"
    echo "$f"
done

cd gif

# Combine GIFs into a PDF
echo -e "\nCombining GIFs to PDF"
magick *.gif "../../${1}-${PAGERESOLUTION}px-${NUMCOLORS}colors-${COLORS}-${BITDEPTH}bits-compressed.pdf"

# Cleanup
cd ../..
rm -rf jpg
