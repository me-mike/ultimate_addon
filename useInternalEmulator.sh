#!/bin/bash
#
# v001 - 02/08/2020 - Initial build
# v002 - 02/08/2020 - Checking for existence of Processed folder, create if not there.
# v003 - 02/08/2020 - Checking to see if it's an emulator we support.  If so, do the work, else skip.  Also reducing output, logging to log.txt
# v004 - 02/08/2020 - Move custom cores to a different folder
# v005 - 02/09/2020 - Adding in image resize for boxart/boxart.png if > 223x307, fixing mame 2010 case statement
# v006 - 02/15/2020 - Adding additional comments when moving UCEs to folders.
#					- Adding some info for Windows CygWin users.  More details coming soon.
#					- Modified to only run if there are UCE files in the current folder.
#					- Check for log.txt before trying to remove it
#					- Added some usage info
#					- Always check to see if the boxart.png is large, and resize it
# v007 - 04/06/2020 - Changing the internal name for the SNES emulator from snes_mtfaust-arm-cortex-a53.so to snes_mtfaust-arm64-cortex-a53.so
#					- Minor comment tweaks
#					- Move folder creation outside of the for loop, since it only needs to make them once
#
# Script requires ffmpeg
# Linux users run: 'sudo apt install ffmpeg' if you don't already have it installed
# For Windows users, download from https://ffmpeg.zeranoe.com/builds/
#      Open zip, copy the ffmpeg.exe from the bin folder to your CygWin sbin folder (D:\cygwin64\usr\sbin)
#      Or copy files from CygWin_sbin to your /usr/sbin folder (or /usr/bin if you don't have sbin in your path)

# Usage: - Ensure you have unsquashfs, mksquashfs, and ffmpeg are in your path - make sure build_sq_cartridge_pack.sh is in same folder as this script.
#    ./useInternalEmulator.sh
# 
# Script will process through all UCE files in the current folder.  It will extract the UCE with unsquashfs to squashfs-root.
# It will then check to see what emulator is in the /emu folder.
#     If it's an emulator built onto the system, it will remove the emulator, modify exec.sh to reference the internal emulator,
#     and rebuild the package.  The original file will be moved to /Processed.  New file will remain in current folder with (BIE) in name.
#     If it's not an internal emulator, move the UCE to the CustomCore folder.

# ToDo:
# 	- Make recursive
#	- Resize boxart images and rebuild if necessary, even if we don't swap the emulator

#Clear our log file from previous output
if [ -e log.txt ]; then
	echo 'Removing old log.txt'
	rm log.txt
fi

#Verify if the Processed folder exists, if not make it
processedFolder=./Processed
if [ ! -d "$processedFolder" ]; then
	echo "Making: $processedFolder"
	mkdir $processedFolder
fi

#Verify if the CustomCore folder exists, if not make it
customCoreFolder=./CustomCore
if [ ! -d "$customCoreFolder" ]; then
		echo "Making: $customCoreFolder"
		mkdir $customCoreFolder
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
	#Get the file name without extension, then add built in emulator "(BIE).UCE" back to it
	outputName=$(echo "$filename" | cut -f 1 -d '.')" (BIE).UCE"

	#Extract out the UCE file to ./squashfs-root
	echo "Extracting $filename"
	unsquashfs "$filename">>log.txt

	#Get the emulator from the emu folder
	for em in "./squashfs-root/emu/*.so"
	do
	#Get just the emulator name, excluding the folder structure
			emulatorName=$(basename $em)
	done

	#Gather image info for boxart.png
	imageInfo=$(file squashfs-root/boxart/boxart.png)
	#Put image info into a array
	IFS=' ' read -ra image_array <<< "$imageInfo"
	#Image width is the 5th element (which is 4 when starting from 0)
	imageWidth=${image_array[4]}

	#If the width of the image is > 223, then resize the image down to 223x307
	if [ $imageWidth -gt 223 ]; then
		echo "Resizing boxart image to 223x307"
		#Resize the image to 223x307
		ffmpeg -i "squashfs-root/boxart/boxart.png" -vf scale=223:307 "squashfs-root/boxart/boxart-new.png">>log.txt 2>&1
		#Copy our resized image over the previous image
		mv squashfs-root/boxart/boxart-new.png squashfs-root/boxart/boxart.png
		#Remove the old squashfs-root/title.png and recreate the symbolic link to boxart.png
		rm squashfs-root/title.png
		ln -s boxart/boxart.png squashfs-root/title.png
		imageResized=1
	else
		echo "Boxart image width: $imageWidth, not resizing"
		imageResized=0
	fi

	#Look at the value of the emulator
        case "$emulatorName" in
			#If it's in our list of internal emulators
			mame2003_plus_libretro.so | mame2010_libretro.so | genesis_plus_gx_libretro.so | quicknes_libretro.so | snes_mtfaust-arm64-cortex-a53.so | stella_libretro.so )
            echo "emulator $emulatorName in list" 
			#Move the original UCE file to ./Processed as a backup
			echo "Moving $filename to $processedFolder" 
			mv "$filename" $processedFolder
			#Remove the emulator from the unpacked folder
			rm squashfs-root/emu/*.so
			#Replace the emulator path in the exec.sh script with the build in emulator path
			sed -i 's/.\/emu\//\/emulator\//g' squashfs-root/exec.sh

			#Rebuild the package with built in emulator name (BIE)
			echo "Building: $outputName"
			./build_sq_cartridge_pack.sh ./squashfs-root "$outputName">>log.txt 2>&1
			;;
			
		#Otherwise if it's not in the list
		* )
			#If the image was resized, let's rebuild the package
			if [ $imageResized -eq 1 ]; then
				echo "emulator $emulatorName not in the list, but image resized, rebuilding package, moving $filename to $customCoreFolder" 
				echo "Building: $filename"
				./build_sq_cartridge_pack.sh ./squashfs-root "$filename">>log.txt 2>&1
			#Custom core, and image wasn't resized, so let's just move to CustomCore folder
			else
				echo "emulator $emulatorName not in the list, moving $filename to $customCoreFolder" 
			fi
			#This UCE has a custom core, so let's move it to a different folder
			mv "$filename" $customCoreFolder
			;;
        esac

	#Remove the extracted folder
	rm -rf squashfs-root/

	echo "=========="
done
# Else if there are no UCEs in the current folder
else
	echo "There must be UCE files in the current folder to process."
fi
