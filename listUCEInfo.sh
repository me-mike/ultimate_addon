#!/bin/bash
#
# v001 - 02/18/2020 - Initial build (code borrowed from useInternalEmulator.sh)

#
# Script is designed to parse through a folder of UCEs, extract them one by one, determine what emulator they have,
#   if they have boxart and size, if they have a bezel and size.  Output goes to UCEInfo.csv so it can be opened with Excel.
#

# Usage: - Ensure you have unsquashfs and that the file is in Unix format (dos2unix listUCEInfo.sh)
#    ./listUCEInfo.sh

#
# To Do:
# - All caught up
#

#Create our UCE info file, and put a header in it
	echo "UCEName,Emulator,BoxArt,BoxArtSize,Bezel,BezelSize">UCEInfo.csv

#Clear our log file from previous output
if [ -e log.txt ]; then
	echo 'Removing old log.txt'
	rm log.txt
fi

#Only run if there are UCE files in the current folder
if ls ./*.UCE &>/dev/null
then
for file in ./*.UCE
do
	#Echo file to screen and log
	echo "Working on $file"
	echo "Working on $file">>log.txt

	#Get just the filename without ./ in front
	filename=${file:2}

	#Extract out the UCE file to ./squashfs-root
	echo "Extracting $filename"
	unsquashfs "$filename">>log.txt

	#Get the emulator from the emu folder
	if ls ./squashfs-root/emu/*.so &>/dev/null
	then
		for em in "./squashfs-root/emu/*.so"
		do
		#Get just the emulator name, excluding the folder structure
				emulatorName=$(basename $em)
		done
	else
		#Else, there is no internal emulator, so we're assuming there is one in exec.sh
		#The line looks like: /emulator/retroplayer /emulator/mame2003_plus_libretro.so "./roms/dkong.zip"
		#Grep to find a line in the file with ".so", and then pull the second parameter from that line which should be the emulator
		emulatorName=$(grep ".so" squashfs-root/exec.sh | awk '{print $2}')
	fi

	#file <imagename.png> outputs in a format like this:
	#addon.z.png: PNG image data, 1280 x 720, 8-bit/color RGBA, non-interlaced
	#Array 0	  1	  2     3     4    5 6    7           8     9

	#Check to see if we have boxart
	if [ -e squashfs-root/boxart/boxart.png ]; then
		#Log that we have boxart
		boxart='Yes'
		#Gather boxart image info for boxart.png
		imageInfo=$(file squashfs-root/boxart/boxart.png)
		#Put image info into a array
		IFS=' ' read -ra image_array <<< "$imageInfo"
		#Image width is the 5th element (which is 4 when starting from 0)
		boxartImageWidth=${image_array[4]}
		boxartImageHeight=${image_array[6]}
		boxartDimensions="$boxartImageWidth x $boxartImageHeight"
	else
		#Log that we don't have box art
		boxart='No'
		boxartDimensions=","
	fi

	#If we have bezel art
	if [ -e squashfs-root/boxart/addon.z.png ]; then
		#Log that we have bezel art
		bezelart='Yes'
		#Gather bezel image info for addon.z.png
		imageInfo=$(file squashfs-root/boxart/addon.z.png)
		#Put image info into a array
		IFS=' ' read -ra image_array <<< "$imageInfo"
		#Image width is the 5th element (which is 4 when starting from 0)
		bezelImageWidth=${image_array[4]}
		bezelImageHeight=${image_array[6]}
		bezelDimensions="$bezelImageWidth x $bezelImageHeight"
	else
		#Log that we don't have bezel art
		bezelart='No'
		bezelDimensions=","
	fi

	#Echo and log the UCE info to UCEInfo.csv: UCE,emulator,boxart,size,bezel,size
	#boxartDimensions and bezelDimensions already have a comma a the end, so don't need to add
	echo "$filename,$emulatorName,$boxart,$boxartDimensions$bezelart,$bezelDimensions"
	echo "$filename,$emulatorName,$boxart,$boxartDimensions$bezelart,$bezelDimensions">>UCEInfo.csv

	#Remove the extracted folder
	rm -rf squashfs-root/
	
	echo "=========="
done
# Else if there are no UCEs in the current folder
else
	echo "There must be UCE files in the current folder to process."
fi
