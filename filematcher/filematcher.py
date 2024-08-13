"""
File matcher
------------
The script scans two specified folders to identify and match files
that have identical contents, even if their names differ. 
It provides a report of unmatched files and any files that 
could not be accessed due to permission issues.

Usage: python script.py <folder1> <folder2>
"""

import glob
import zlib
import os
import sys

# Check if the correct number of arguments is provided
if len(sys.argv) != 3:
    print(f"Usage: python {os.path.basename(sys.argv[0])} <folder1> <folder2>")
    sys.exit(1)

# The two folders to compare and match files by content
folder1 = sys.argv[1]
folder2 = sys.argv[2]

# function to calculate file crc32
def crc32(fileName):
    with open(fileName, 'rb') as fh:
        hash = 0
        while True:
            s = fh.read(65536)
            if not s:
                break
            hash = zlib.crc32(s, hash)
        return "%08X" % (hash & 0xFFFFFFFF)


# list all files in folder1 and 2
files1 = glob.glob(folder1 + "/**/*.*", recursive=True)
files2 = glob.glob(folder2 + "/**/*.*", recursive=True)
length = len(files1 + files2)

# dictionary to collect identical files, the keys are crc32 hashes
dic = {}

# collect permission errors
permerrors = []

cnt = 1
for f in files1 + files2:

    # skip folders
    if os.path.isdir(f):
        continue
        
    # progress in percentage
    print(cnt,"/",length, round(cnt/length*100,2), "%", f)
    cnt += 1

    try:
        key = crc32(f)
    except PermissionError:
        permerrors.append(f)
        
    if key not in dic:
        dic[key] = []
    dic[key].append(f)

print("------\nFiles without pair:")

for key in dic:
    if len(dic[key]) == 1:
        print(dic[key])

print("------\nFiles with permission errors:")

for f in permerrors:
    print(f)

input("Press ENTER to exit")