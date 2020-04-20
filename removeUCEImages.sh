#!/bin/bash
#
# v001 - 04/19/2020 - Initial build
# v002 - 04/19/2020 - Added check to ensure build script was in this folder
#					- Skip items in the noImage folder since they've already been processed
# v003 - 04/20/2020 - Adding checks for required executables

# Usage: - Ensure you have unsquashfs, mksquashfs, touch, and sed in your path.  Make sure build_sq_cartridge_pack.sh is in same folder as this script.
#    ./removeUCEImages.sh
# 
# Script will process through all UCE files in the current folder and sub-folders.  It will extract the UCE with unsquashfs to squashfs-root.
# It will then strip out any boxart and bezel images, modify the exec.sh as necessary, and repackage the UCE with (noImage) in the name.
# It will move the (noImage).UCE file into a /noImage folder, similar to where the original came from.

# Note: This should only be run on UCEs built with the addon_tool.  Any UCE built manually with custom code in exec.sh will not work.

# ToDo:
#   - All caught up

#Verify if the build_sq_cartridge_pack.sh is in this folder
if [ ! -f build_sq_cartridge_pack.sh ]; then
	echo "Need to have build_sq_cartridge_pack.sh in this folder to run the script"
	exit 1
fi

#Verify all of the executables we need are in our path.  Otherwise exit.
if ! [ -x "$(command -v unsquashfs)" ]; then
  echo 'Error: unsquashfs is not in path.' >&2
  exit 1
fi
if ! [ -x "$(command -v mksquashfs)" ]; then
  echo 'Error: mksquashfs is not in path.' >&2
  exit 1
fi
if ! [ -x "$(command -v touch)" ]; then
  echo 'Error: touch is not in path.' >&2
  exit 1
fi
if ! [ -x "$(command -v sed)" ]; then
  echo 'Error: sed is not in path.' >&2
  exit 1
fi
if ! [ -x "$(command -v ln)" ]; then
  echo 'Error: ln is not in path.' >&2
  exit 1
fi

echo "All required commands in path"

#Clear our log file from previous output
if [ -e log.txt ]; then
	echo 'Removing old log.txt'
	rm log.txt
fi

#Verify if the noImage folder exists, if not make it
noImageFolder=./noImage
if [ ! -d "$noImageFolder" ]; then
	echo "Making: $noImageFolder"
	mkdir $noImageFolder
fi

#IFS is the internal field separator.  To handle folders with spaces in the name, let's backup
# the existing IFS value, and set it only to spaces and new lines.
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

#Allow script to go recursive.  Search from here on down for UCE files.  Exclude items in our ./noImage folder.
for file in $(find . -type f -name "*.UCE" -not -path "./noImage*")
do
	#Echo file to screen and log
	echo "Working on $file"
	echo "Working on $file">>log.txt

	#Get just the filename without ./ in front
	filename=${file:2}
	#Now get just the folder name without the UCE
	dirname=$(dirname $filename)
	#Get the file name without extension, then add "(noImage).UCE" back to it
	outputName=$(echo "$filename" | cut -f 1 -d '.')" (noImage).UCE"

	#Extract out the UCE file to ./squashfs-root
	echo "Extracting $file"
	unsquashfs "$file">>log.txt

	#Initialize a couple of variables to 0 (false) to determine if we had boxart or bezel
	hadBoxArt=0
	hadBezelArt=0
	hadImages=0

	#Remove boxart.png if it exists
	if [ -f "squashfs-root/boxart/boxart.png" ]; then
		#We found boxart, set variable to true (1)
		hadBoxArt=1
		echo "Removing squashfs-root/boxart/boxart.png"
		rm squashfs-root/boxart/boxart.png
		touch squashfs-root/boxart/boxart.png
		#Remove the squashfs-root/title.png
		rm squashfs-root/title.png
		ln -s boxart/boxart.png squashfs-root/title.png
	fi

	#Remove addon.z.png if it exists
	if [ -f "squashfs-root/boxart/addon.z.png" ]; then
		#We found bezel art, set variable to true (1)
		hadBezelArt=1
		echo "Removing squashfs-root/boxart/addon.z.png"
		rm squashfs-root/boxart/addon.z.png
		#Remove the bezelart image commands from the exec.sh file
		sed -i -e '/addon.z.png/d' squashfs-root/exec.sh
		sed -i -e '/gameinfo.ini/d' squashfs-root/exec.sh
	fi

	hadImages=$(($hadBoxArt+$hadBezelArt))

	#If we had box art or bezel art (if adding them together is greater than 0, one of them was at least 1)
	if [ $hadImages -gt 0 ]; then
		#Create folders inside /noImage for storing our modified UCE if they don't already exist
		if [ ! -d "$noImageFolder/$dirname" ]; then
			echo "Making: $noImageFolder/$dirname"
			mkdir --parents "$noImageFolder/$dirname"
		fi
		#Rebuild the package with built in emulator name (BIE)
		echo "Building: $outputName"
		./build_sq_cartridge_pack.sh ./squashfs-root "$outputName">>log.txt 2>&1
		#Move the modified UCE file to ./noImage folder
		echo "Moving $outputName to $noImageFolder/$dirname" 
		mv "$outputName" "$noImageFolder/$dirname"
	fi

	#Remove the extracted folder
	rm -rf squashfs-root/

	echo "=========="
done

#Restore the previous IFS value
IFS=$SAVEIFS
