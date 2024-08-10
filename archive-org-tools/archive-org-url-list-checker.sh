#!/bin/bash

######################################
# archive.org URL availability checker
#
# Checks if the URLs found in the 
# specified .txt file are archived on archive.org
# 
# Usage:
#        chmod +x script.sh
#        archive-org-url-list-checker.sh urls.txt
#
# Example output:
#         https://example.com MISSING
#         https://example.com OK
#         ...

if [ $# -lt 1 ]
then
    echo "Usage $0 urllist.txt"
    exit 1
fi

while IFS= read -r line
do
    line=$(echo $line | tr -d "\n\r") # strip

    curl --head --connect-timeout 60 --max-time 120 --retry 8 --retry-all-errors --silent \
        https://web.archive.org/web/0id_/$line \
        | grep "location" | grep --invert-match "x-location" \
        >/dev/null
    
    if [ $? -eq 0 ]; then
        echo $line OK
    else
        echo $line MISSING
    fi
done < "$1"