#!/bin/bash
#
# v001 - 04/06/2020 - Initial build
#
# Script requires ffmpeg
# Linux users run: 'sudo apt install ffmpeg' if you don't already have it installed
# For Windows users, download from https://ffmpeg.zeranoe.com/builds/
#      Open zip, copy the ffmpeg.exe from the bin folder to your CygWin sbin folder (D:\cygwin64\usr\sbin)
#      Or copy files from CygWin_sbin to your /usr/sbin folder --If you don't have sbin in your path, use /usr/bin

# Usage: - Ensure you have unsquashfs, mksquashfs, and ffmpeg in your path.  Make sure build_sq_cartridge_pack.sh is in same folder as this script.
#    ./resizeUCEBoxartImages.sh
# 
# Script will process through all UCE files in the current folder and sub-folders.  It will extract the UCE with unsquashfs to squashfs-root.
# It will then check the boxart image size and resize if necessary.
# If nothing needs to be done, the file will be left alone.  If boxart needs to be resized, the original UCE will be moved to an /Original folder,
# the boxart will be resized, and the UCE repackaged in its original location with the same name.

# ToDo:
#   - Maybe consider inserting a generic bezel if one isn't included?  Get feedback first.

#Clear our log file from previous output
if [ -e log.txt ]; then
	echo 'Removing old log.txt'
	rm log.txt
fi

#Verify if the Original folder exists, if not make it
originalFolder=./Original
if [ ! -d "$originalFolder" ]; then
	echo "Making: $originalFolder"
	mkdir $originalFolder
fi

#IFS is the internal field separator.  To handle folders with spaces in the name, let's backup
# the existing IFS value, and set it only to spaces and new lines.
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

#Allow script to go recursive.  Search from here on down for UCE files.
for file in $(find . -type f -name "*.UCE")
do
	#Echo file to screen and log
	echo "Working on $file"
	echo "Working on $file">>log.txt

	#Get just the filename without ./ in front
	filename=${file:2}
	#Now get just the folder name without the UCE
	dirname=$(dirname $filename)

	#Extract out the UCE file to ./squashfs-root
	echo "Extracting $file"
	unsquashfs "$file">>log.txt

	#Gather image info for boxart.png
	imageInfo=$(file squashfs-root/boxart/boxart.png)
	#Put image info into a array
	IFS=' ' read -ra image_array <<< "$imageInfo"
	#Image width is the 5th element (which is 4 when starting from 0)
	imageWidth=${image_array[4]}
	imageHeight=${image_array[6]}
	boxartDimensions="$imageWidth x $imageHeight"

	#If the width of the image is > 223, then resize the image down to 223x307
	if [ $imageWidth -gt 223 ]; then
		echo "Original boxard dimensions $boxartDimensions resizing to 223x307"
		#Resize the image to 223x307
		ffmpeg -i "squashfs-root/boxart/boxart.png" -vf scale=223:307 "squashfs-root/boxart/boxart-new.png">>log.txt 2>&1
		#Copy our resized image over the previous image
		mv squashfs-root/boxart/boxart-new.png squashfs-root/boxart/boxart.png
		#Remove the old squashfs-root/title.png and recreate the symbolic link to boxart.png
		rm squashfs-root/title.png
		ln -s boxart/boxart.png squashfs-root/title.png
		#Create folders inside /Original for storing our original UCE if they don't already exist
		if [ ! -d "$originalFolder/$dirname" ]; then
			echo "Making: $originalFolder/$dirname"
			mkdir --parents "$originalFolder/$dirname"
		fi
		#Move the original UCE file to ./Original as a backup
		echo "Moving $file to $originalFolder/$dirname" 
		mv "$file" "$originalFolder/$dirname"
		#Rebuild the package with built in emulator name (BIE)
		echo "Building: $file"
		./build_sq_cartridge_pack.sh ./squashfs-root "$file">>log.txt 2>&1
	else
		echo "Boxart image dimensions: $boxartDimensions not resizing"
	fi

	#Remove the extracted folder
	rm -rf squashfs-root/

	echo "=========="
done

#Restore the previous IFS value
IFS=$SAVEIFS