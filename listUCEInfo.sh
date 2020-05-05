#!/bin/bash
#
# v001 - 02/18/2020 - Initial build (code borrowed from useInternalEmulator.sh)
# v002 - 02/18/2020 - Added last modified date of the UCE
# v003 - 03/21/2020 - Recursive searches into folders for UCEs
# v004 - 03/21/2020 - Small fix to double quote the file names.  A few UCEs may have commas in the name.
# v005 - 03/21/2020 - Look for samples, CHDs, or nvram -- Requires zipinfo utility, included in the "unzip" cygwin package
# v006 - 04/10/2020 - Print the date/timestamp and size of the core so we can identify how old it might be
# v007 - 04/20/2020 - Adding checks for required executables

#
# Script is designed to recursively parse through a folder of UCEs, extract them one by one, determine what emulator they have,
#   if they have boxart and size, if they have a bezel and size.  Output goes to UCEInfo.csv so it can be opened with Excel.
#

# Usage: - Ensure you have unsquashfs and zipinfo (from cygwin unzip package) and that the file is in Unix format (dos2unix listUCEInfo.sh)
#    ./listUCEInfo.sh

#
# To Do:
# - Add help text to command line
# - Look at generating functions to make code reusable
#

#Verify all of the executables we need are in our path.  Otherwise exit.
if ! [ -x "$(command -v unsquashfs)" ]; then
  echo 'Error: unsquashfs is not in path.' >&2
  exit 1
fi
if ! [ -x "$(command -v zipinfo)" ]; then
  echo 'Error: zipinfo is not in path.' >&2
  exit 1
fi
if ! [ -x "$(command -v file)" ]; then
  echo 'Error: file is not in path.' >&2
  exit 1
fi
if ! [ -x "$(command -v grep)" ]; then
  echo 'Error: grep is not in path.' >&2
  exit 1
fi
if ! [ -x "$(command -v find)" ]; then
  echo 'Error: find is not in path.' >&2
  exit 1
fi
if ! [ -x "$(command -v basename)" ]; then
  echo 'Error: basename is not in path.' >&2
  exit 1
fi

echo "All required commands in path"

#Create our UCE info file, and put a header in it
echo "UCEName,Emulator,EmulatorDate,EmulatorSize,BoxArt,BoxArtSize,Bezel,BezelSize,LastModified,HasSamples,HasCHDs,HasNVRAM">UCEInfo.csv

#Clear our log file from previous output
if [ -e log.txt ]; then
	echo 'Removing old log.txt'
	rm log.txt
fi

#IFS is the internal field separator.  To handle folders with spaces in the name, let's backup
# the existing IFS value, and set it only to spaces and new lines.
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

for file in $(find . -type f -name "*.UCE")
do
	#Echo file to screen and log
	echo "Working on $file"
	echo "Working on $file">>log.txt

	#Initialize samples, CHDs, and nvram to No
	hasSamples="No"
	hasCHDs="No"
	hasNvram="No"

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

			#Get the date/timestamp of the emulator
			emulatorDate=$(date -r $em "+%m-%d-%Y %H:%M:%S")

			#Get the emulator size
			emulatorSize=$(find $em -printf %s)

			#If the emulator is MAME 2003 or 2010, let's look for samples, CHDs, or nvram files
			if [[ $emulatorName == mame2003* ]] || [[ $emulatorName == mame2010* ]];
			then
				#Run the zipinfo command to get a list of items in our game rom
				romInfo=$(zipinfo -1 ./squashfs-root/roms/*.zip)
				#Check to see if we have a samples folder in the rom zip
				if [[ $romInfo == *samples/* ]];
				then
					hasSamples="Yes"
				fi
				#Check to see if we have a chd folder in the rom zip
				if [[ $romInfo == *chd/* ]];
				then
					hasCHDs="Yes"
				fi
				#Check to see if we have a nvram folder in the rom zip
				if [[ $romInfo == *nvram/* ]];
				then
					hasNvram="Yes"
				fi
			fi
		done
	else
		#Else, there is no internal emulator, so we're assuming there is one in exec.sh
		#The line looks like: /emulator/retroplayer /emulator/mame2003_plus_libretro.so "./roms/dkong.zip"
		#Grep to find a line in the file with ".so", and then pull the second parameter from that line which should be the emulator
		emulatorName=$(grep ".so" squashfs-root/exec.sh | awk '{print $2}')
		#Set a dummy emulatorDate
		emulatorDate="Internal"
		emulatorSize="Internal"
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

	#Get the last modified time of the UCE file
	lastModUCE=$(date -r "$filename" "+%Y/%m/%d %H:%M:%S")

	#Echo and log the UCE info to UCEInfo.csv: UCE,emulator,boxart,size,bezel,size
	#boxartDimensions and bezelDimensions already have a comma a the end, so don't need to add
	echo "$filename,$emulatorName,$emulatorDate,$emulatorSize,$boxart,$boxartDimensions$bezelart,$bezelDimensions$lastModUCE,$hasSamples,$hasCHDs,$hasNvram"
	echo "\"$filename\",$emulatorName,$emulatorDate,$emulatorSize,$boxart,$boxartDimensions$bezelart,$bezelDimensions$lastModUCE,$hasSamples,$hasCHDs,$hasNvram">>UCEInfo.csv

	#Remove the extracted folder
	rm -rf squashfs-root/
	
	echo "=========="
done

#Restore the previous IFS value
IFS=$SAVEIFS
