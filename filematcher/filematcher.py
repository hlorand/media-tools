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

# collect permission errors
permerrors = []

# function to calculate file crc32
def crc32(fileName):
    try:
        with open(fileName, 'rb') as fh:
            hash = 0
            while True:
                s = fh.read(65536)
                if not s:
                    break
                hash = zlib.crc32(s, hash)
            return "%08X" % (hash & 0xFFFFFFFF)
    except:
        permerrors.append(fileName)


# list all files in folder1 and 2
files1 = glob.glob(folder1 + "/**/*.*", recursive=True)
files2 = glob.glob(folder2 + "/**/*.*", recursive=True)
length = len(files1 + files2)

# dictionary to collect identical files, the keys are crc32 hashes
dic = {}

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


print("------\nFiles with pair: filematcher-withpair.txt")

with open("filematcher-withpair.txt", "w", encoding='utf-8') as f:
    for key in dic:
        if len(dic[key]) >= 2:
            print( ";".join( dic[key] ), file=f)

print("------\nFiles with different CRC but matching filename pair in the other folder on the same relative path: filematcher-withpair-differentcrc.txt")

pairs = []
exclude = set()
for key in dic.copy():
    if len(dic[key]) == 1:
        # check other folder for same filename
        filepath = dic[key][0]
        if folder1 in filepath:
            filepath = filepath.replace(folder1, folder2)
        else:
            filepath = filepath.replace(folder2, folder1)
            
        if os.path.exists(filepath):
            othercrc = crc32(filepath)
            pair = sorted([ dic[key][0], dic[othercrc][0] ])
            if pair not in pairs:
                pairs.append( pair )
            exclude.add(key)
            exclude.add(othercrc)

with open("filematcher-withpair-differentcrc.txt", "w", encoding='utf-8') as f:
    for a,b in pairs:
        print( a, b, os.path.getsize(a), os.path.getsize(b), os.path.getmtime(a), os.path.getmtime(b), sep=";", file=f)

print("------\nFiles without pair: filematcher-withoutpair.txt")

with open("filematcher-withoutpair.txt", "w", encoding='utf-8') as f:
    for key in dic:
        if len(dic[key]) == 1 and key not in exclude:
            print(dic[key][0], file=f)

print("------\nFiles with permission errors: filematcher-permerrors.txt")

with open("filematcher-permerrors.txt", "w", encoding='utf-8') as f:
    for perm in permerrors:
        print(perm, file=f)

input("Press ENTER to exit")

