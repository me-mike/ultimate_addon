#!/bin/bash
#
# v001 - 02/08/2020 - Initial build
# v002 - 02/08/2020 - Checking for existence of Processed folder, create if not there.
# v003 - 02/08/2020 - Checking to see if it's an emulator we support.  If so, do the work, else skip.  Also reducing output, logging to log.txt
# v004 - 02/08/2020 - Move custom cores to a different folder
# v005 - 02/09/2020 - Adding in image resize for boxart/boxart.png if > 223x307, fixing mame 2010 case statement
#
# Script requires ffmpeg, run: 'sudo apt install ffmpeg' if you don't already have it installed
#

#Clear our log file from previous output
rm log.txt

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

	#Get the emulator from the emu folder
        for em in "./squashfs-root/emu/*.so"
        do
		#Get just the emulator name, excluding the folder structure
                emulatorName=$(basename $em)
        done

	#Echo to the screen for debug
        #echo emulatorName: $emulatorName

	#Look at the value of the emulator
        case "$emulatorName" in
		#If it's in our list of internal emulators
                mame2003_plus_libretro.so | mame2010_libretro.so | genesis_plus_gx_libretro.so | quicknes_libretro.so | snes_mtfaust-arm-cortex-a53.so | stella_libretro.so )
                        echo "emulator $emulatorName in list" 
			#Move the original UCE file to ./Processed as a backup
		        mv "$filename" $processedFolder
		        #Remove the emulator from the unpacked folder
		        rm squashfs-root/emu/*.so
		        #Replace the emulator path in the exec.sh script with the build in emulator path
		        sed -i 's/.\/emu\//\/emulator\//g' squashfs-root/exec.sh

			#Gather image info for boxart.png
			imageInfo=$(file squashfs-root/boxart/boxart.png)
			#Put image info into a array
			IFS=' ' read -ra image_array <<< "$imageInfo"
			#Image width is the 5th element (which is 4 when starting from 0)
			imageWidth=${image_array[4]}
			echo "Boxart image width: $imageWidth"

			#If the width of the image is > 223, then resize the image down to 223x307
			if [ $imageWidth -gt 223 ]; then
				echo "Resizing boxart image to 223x307"
				#Resize the image to 223x307
				ffmpeg -i "squashfs-root/boxart/boxart.png" -vf scale=223:307 "squashfs-root/boxart/boxart-new.png">>log.txt
				#Copy our resized image over the previous image
				mv squashfs-root/boxart/boxart-new.png squashfs-root/boxart/boxart.png
				#Remove the old squashfs-root/title.png and recreate the symbolic link to boxart.png
				rm squashfs-root/title.png
				ln -s boxart/boxart.png squashfs-root/title.png
			fi


		        #Rebuild the package with built in emulator name (BIE)
			echo "Building: $outputName"
		        ./build_sq_cartridge_pack.sh ./squashfs-root "$outputName">>log.txt
			;;
		#Otherwise if it's not in the list
                * )
                        echo "emulator $emulatorName not in the list" 
		        #This UCE has a custom core, so let's move it to a different folder
		        mv "$filename" $customCoreFolder
			;;
        esac

	#Remove the extracted folder
	rm -rf squashfs-root/

	echo "=========="
done
