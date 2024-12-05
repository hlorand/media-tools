#!/bin/bash

if ! which gs &> /dev/null
then
  echo "Install ghostscript to continue."
  exit
fi

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <input.pdf>"
    exit 1
fi

# /screen=72dpi, /ebook=150, /prepress=300
gs -sDEVICE=pdfwrite \
   -dCompatibilityLevel=1.4 \
   -dNOPAUSE -dQUIET -dBATCH \
   -sOutputFile=$1.compressed.pdf \
   -dPDFSETTINGS=/ebook \
   $1


