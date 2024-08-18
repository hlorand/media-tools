#!/bin/bash    

###########
# KEYGENMUSIC CONVERTER
###########
# This bash script converts every "keygen music" (*.mod *.xm *.it *.s3m *.mtm *.stm)
# in the current folder to mp3 using VLC Media player. It supports every media format that 
# VLC supports. Edit VLC executable path below according to your operating system.
#
# Usage: chmod +x script.sh; ./script.sh
#
# @see https://wiki.videolan.org/Transcode/#Command-line
###########

# change working dir to current dir
cd -- "$(dirname "$0")"

# VLC executable path
if [[ "$OSTYPE" == "darwin"* ]]
then
    vlcpath="/Applications/VLC.app/Contents/MacOS/VLC"
elif [[ "$OSTYPE" == "linux"* ]]
then
    vlcpath="/usr/bin/vlc"
else
    echo "Please provide VLC Media Player executable path:"
    read vlcpath
fi

if [ ! -e "$vlcpath" ]; then
    echo "Command '$vlcpath' does not exist, specify the right executable path in the script"
    exit 1
fi

# audio settings
bitrate="320"

(
IFS=$'\n'

FILES=$(find ./ -not -path '*/.*' \( -iname "*.mod" -o -iname "*.xm" -o -iname "*.it" \
                                  -o -iname "*.s3m" -o -iname "*.mtm" -o -iname "*.stm"  \) )
for file in $FILES
do
    # check if converted mp3 already exsists
    if [ -f "$file".mp3 ]
    then
    	echo "Skipping $file.mp3 - already exsists."
    else
    	echo "=> Transcoding $file ... "

        destination=$(dirname "$file")
        newfile=$(basename "$file" | sed 's@\.[a-z][a-z][a-z]$@@').mp3

        $vlcpath -I dummy -q "$file" \
           --sout "#transcode{acodec=mp3,ab=$bitrate}:standard{mux=raw,dst=\"$destination/$newfile\",access=file}" \
           vlc://quit
        ls -lh "$file" "$destination/$newfile"
        echo
    fi
done
)

echo "CONVERSION ENDED"