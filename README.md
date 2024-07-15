Media tools
===========

[video-reencode.sh](video-reencode/video-reencode.sh)
--------------------

It converts the video files (mp4, m4v, mkv, avi, mpg) found in the folder (and subfolders) to .mp4 format with the specified settings using ffmpeg.

It sets the configurations through a series of questions. It's almost like an ffmpeg GUI, but in the command line.

```text
Choose a resolution:
1) 426x240  2) 640x360   3) 854x480
4) 1280x720 5) 1920x1080 6) 2560x1440 7) 3840x2160
#? 2

Choose a Compression Rate Factor CRF (recommended: 26)
(bigger number = more compression, smaller number = quality):
1) 30  2) 28  3) 26
4) 24  5) 22  6) 20
#? 3

Choose a FPS Frames Per Second value (recommended: 30):
 1) 60   2) 30   3) 25   4) 24   5) 20
 6) 15   7) 10   8) 5    9) 4   10) 2   11) 1
...
```

- It preserves the folder structure. 
- It appends ".compressed.mp4" to the end of the filenames. 
- Deletes old files.

Usage: Place the script in a folder where video files are located. `chmod +x script.sh; ./script.sh`

----

[mp3-merge.sh](mp3-merge/mp3-merge.sh)
--------------------

Merges every .mp3 file in the current folder using ffmpeg into merged.mp3

----

[mp4-merge.sh](mp4-merge/mp4-merge.sh)
---------------------

Finds every MP4 file in subfolders and merges them into a single .mp4 file. Filename: Parent-folder-name.mp4 

Creates chapters for the merged video. Certain media players can use this information. *For example: In VLC, go to Playback menu > Chapters > Jump to chapter.*
