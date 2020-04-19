# useInternalEmulator.sh

I wrote a Linux script to take all of the UCEs in the current folder, extract them, delete the emulator from the emu folder, modify the exec.sh script to change the path to the emulator from the UCE's copy to the internal Legend's Arcade emulator, and then repackage the UCE with a (BIE) in the name, standing for Built In Emulator. I've run this against games using mame2003_plus_libretro.so, and it's greatly reduced the file since since it doesn't need the emulator built into the package.

The script assumes build_sq_cartridge_pack.sh is in the same folder as this script.  Customizations were made on this fork for the scripts to work together.

Make sure useInternalEmulator.sh and build_sq_cartridge_pack.sh have executable access, run 'chmod 755 *.sh' in that folder.

Also ensure all of the script files are in Unix format: 'dos2unix *.sh'

The script requires ffmpeg to reduce boxart images to save space, run: 'sudo apt install ffmpeg' if you don't already have it installed.

To execute the script, simply run it like this, and it will parse through all UCE files in the folder, extract them, see if it can modify the emulator, shrink box art images, and build a new UCE:
./useInternalEmulator.sh

Updated UCEs with (BIE) in the name will be in the current folder.
Processed UCEs will be moved to Processed. You may choose to delete these if you're happy with the (BIE) versions, but keep them to be safe unless you need the space.
UCEs that aren't converted because they use custom emulators go into a CustomCore folder.

## To Do
-- Make script recursive, updating items in subfolders
-- Resize boxart images and rebuild if necessary, even if we don't swap the emulator

# Using useInternalEmulator.sh on Windows

The useInternalEmulator.sh and build_sq_cartridge_pack.sh are shell scripts meant to be run on Linux environments.  To be able to run this, we need a Linux-like environment on Windows.  To do this, we install CygWin from here:  https://www.cygwin.com/.  If you're already intimidated, you might want to stop now.  If you're willing to learn, let's go on an adventure together.  I'm going to assume you have a 64-bit Windows system.  If you have a 32-bit system, you may have to work some of this out on your own....

1 - Download setup-x86_64.exe from CygWin (https://www.cygwin.com/setup-x86_64.exe), and install it on your Windows machine.  For reference, I installed it to D:\cygwin64, so any path I mention will reference that location.

2 - Now that you have CygWin installed, we need to add additional packages to it.  Relaunch setup-x86_64.exe and click Next until you get to the Select Packages screen.  From here, we're going to search for and install the following packages (select View: Full, and search for these packages).  For each package, change Skip to the latest non-test version of each package below:
   xxd                Hexdump utility
   e2fsprogs          EXT 2, 3, 4 filesystem utilities
   dos2unix           Line break conversion - Allows us to convert files from Windows line endings to Unix line endings

Optional Packages if you don't want to use my EXE files for unsquashfs.exe or mksquashfs.exe:
   gcc-core           GCC compiler collection 
   cygwin32-gcc-core  GCC for cygwin 32bit toolchain.  32bit users would need cygwin64-gcc-core
   xz                 LZMA de/compressor
   liblzma5           LZMA de/compressor library (runtime)
   liblzma-devel      LZMA de/compressor library (development)
   
Click Next to complete the CygWin package updates.  Accept any additional package requirements from above.

3 - Download my CygWin_sbin.zip file (https://github.com/me-mike/ultimate_addon/blob/master/CygWin_sbin/CygWin_sbin.zip) from GitHub, and extract it to your CygWin /usr/sbin folder.  For me this is D:\cygwin64\usr\sbin (don't overwrite any DLLs already present).  Note: If you won't want to trust the EXEs, I'll include instructions below for building unsquashfs.exe and mksquashfs.exe, which will require you to have the Optional Packages installed above.  ** NOTE: Some users have had issues with the executables in /usr/sbin.  If they don't work for you, try /usr/local/bin **

We also need ffmpeg for Windows.  You could go to https://ffmpeg.org/download.html, download the source code, and try to compile it, or trust the people they trust, and go to https://ffmpeg.zeranoe.com/builds/, click the Download Build button, and then extract ffmpeg.exe to your CygWin /usr/sbin folder.  For me this is D:\cygwin64\usr\sbin.  ** NOTE: Some users have had issues with the executables in /usr/sbin.  If they don't work for you, try /usr/local/bin **

4 - Modify your CygWin /etc/profile (D:\cygwin64\etc\profile) file to add /usr/sbin to your path, so it will pick up the executables we added.  On lines 45 and 47 we'll be adding :/usr/sbin to our PATH.  It will look like this:
	PATH="/usr/local/bin:/usr/bin:/usr/sbin${PATH:+:${PATH}}"
    else
	PATH="/usr/local/bin:/usr/bin:/usr/sbin"

5 - From your Windows Start Menu, run Cygwin64 Terminal.  It should be in the CygWin folder.  This is similar to a Windows command prompt.

6 - Change directories in your Cygwin64 Terminal to where you have downloaded the scripts.  Remember, we're on Windows but using Linux like paths.  The pushd command takes us from our current folder, and moves us to another location.  Linux is case sensitive, so you have to make sure your path is exactly right.  The good news is you can type a few characters and hit the Tab key, and it will try to auto-complete a folder or file name.  I'll give a few Windows examples of folders, and the commands we'd use to move to that location.  /cygdrive is how CygWin recoginizes drives on Windows systems.  The next item is our drive letter, like C or D, but lowercase.  Then the rest is just a normal path using Linux slashes (/) instead of Windows backslashes (\).  Note, it's best if you use a folder without spaces or special characters in the name to make navigating there easier:

  Windows Location                                  Command to move us there
  C:\Users\miken\Desktop                            pushd /cygdrive/c/Users/miken/Desktop
  D:\UCEs                                           pushd /cygdrive/d/UCEs

This folder we have just moved to should have at least 3 files in it.  It needs both of our script files, useInternalEmulator.sh and build_sq_cartridge_pack.sh, and at least 1 UCE file.

7 - Now we're going to run a command to ensure our script files are in Unix line ending format.  From your Cygwin64 Terminal, run the following command:
   dos2unix *.sh

8 - Now it's time to run the script.  From your Cygwin64 Terminal run the following command:
   ./useInternalEmulator.sh

If everything went well, the script should have found your UCE file, extracted it, checked to see if it needed to resize the boxart.png file, determined what emulator is used inside the UCE, and either built a new package or just moved your UCE somewhere else.  FAQs with errors will be coming later.

## Compiling unsquashfs.exe and mksquashfs.exe for Windows with CygWin

You're smart.  You don't like using EXEs from strangers.  You want to build unsquashfs.exe and mksquashfs.exe on your own to ensure there's nothing funny going on.  If you've made it this far, you might as well give this a shot.

Squashfs (Squash File System) is a compressed read-only file system for Linux. Squashfs compresses files, inodes and directories, and supports block sizes from 4 KiB up to 1 MiB for greater compression. It's basically like a zip file.  unsquashfs.exe extracts UCE files, and mksquashfs.exe builds the squashfs file system containing our ROMs, images, scripts, etc.  See image below.  Instructions oringally found here: https://stackoverflow.com/questions/36478351/how-to-handle-squashfs-in-windows

1 - Ensure you have the optional packages from Step 2 above installed for CygWin.

2 - Download the squashfs source code from here:  https://github.com/plougher/squashfs-tools (click the green download button, and download it)

3 - Extract the zip file somewhere.  Note, it's best if you use a folder without spaces or special characters in the name to make navigating there easier.  Edit the Makefile in the squashfs-tools folder.  Uncomment the following lines:

XZ_SUPPORT = 1
LZMA_XZ_SUPPORT = 1

4 - From your Windows Start Menu, run Cygwin64 Terminal.  It should be in the CygWin folder.  This is similar to a Windows command prompt.  Navigate to this folder with the pushd command described above.  For me this was: pushd /cygdrive/c/Users/miken/Desktop/UCEBuild/squashfs-tools-master/squashfs-tools

Run this command to compile the code:
make EXTRA_CFLAGS="-Dlinux -DFNM_EXTMATCH='(1<<5)' -D'sigtimedwait(a,b,c)=sigwaitinfo(a,b)'"

Run this command to install the code:
make install

These files will be copied to /usr/local/bin.

# listUCEInfo.sh

listUCEInfo.sh is based off of the code for useInternalEmulator.sh.  It is meant to be run in a Linux environment, or in Windows using CygWin.  See details above for getting that configured.  Run this script in a folder and it will recursively look for UCE files.  It will extract them one by one, pull the UCE name, determine the emulator built into the package, or if there is no emulator built in, it looks at the exec.sh script to determine what ALU core you're using.  It then determines if you have boxart and the dimensions, then looks for the bezel and gets the dimensions.  It also checks MAME 2003 and 2010 ROM files to see if they have samples, CHDs, or nvram files included in them.  It outputs all of this information to the screen, and outputs to a UCEInfo.csv file.  It then deletes the temporary extract, and moves to the next UCE in the folder.  All of this work takes less than 1 second per UCE.

Requires unsquashfs and zipinfo to run.

On Linux, make sure listUCEInfo.sh has executable access, run 'chmod 755 *.sh' in that folder.

Also ensure all of the script files are in Unix format: 'dos2unix *.sh'

To execute the script, simply run it like this:
./listUCEInfo.sh

Output: UCEInfo.csv

## To Do
-- All caught up.  I'm willing to take suggestions.

# resizeUCEBoxartImages.sh

resizeUCEBoxartImages.sh is based off of the code for useInternalEmulator.sh.  It is meant to be run in a Linux environment, or in Windows using CygWin.  See details above for getting that configured.  Run this script in a folder and it will recursively look for UCE files.  It will extract them one by one, check the boxart image size, and resize it if necessary.  If it resizes an image, it will move the original UCE into a folder structure in /Original similar to where it found the original UCE file and rebuild the new UCE in the original location.

Ensure you have unsquashfs, mksquashfs, and ffmpeg in your path.  Make sure build_sq_cartridge_pack.sh is in same folder as this script.

On Linux, make sure resizeUCEBoxartImages.sh has executable access, run 'chmod 755 *.sh' in that folder.

Also ensure all of the script files are in Unix format: 'dos2unix *.sh'

To execute the script, simply run it like this:
./resizeUCEBoxartImages.sh

# removeUCEImages.sh

removeUCEImages.sh is based off of the code for useInternalEmulator.sh.  It is meant to be run in a Linux environment, or in Windows using CygWin.  See details above for getting that configured.  Run this script in a folder and it will recursively look for UCE files.  It will extract them one by one, remove any boxart or bezel art, recreate 0k files for the boxart and title.png files since they need something there, and will rebuild the UCE, adding (noImage) to the name.  The file will be placed in a ./noImage folder with the same folder structure as the original UCE.

Ensure you have unsquashfs, mksquashfs, touch, and sed in your path.  Make sure build_sq_cartridge_pack.sh is in same folder as this script.

On Linux, make sure removeUCEImages.sh has executable access, run 'chmod 755 *.sh' in that folder.

Also ensure all of the script files are in Unix format: 'dos2unix *.sh'

To execute the script, simply run it like this:
./removeUCEImages.sh

# Community Add-on 

## (Last verified on firmware version 4.13.0)

This is an unofficial guide to packing your own apps into an  "Add-on Image" for use on AtGames' Legend Ultimate home arcade. 

## Disclaimer
We are not obligated to provide updates or fixes to this guide. We are not responsible if the app you developed damages or voids the warranty on the Legends Ultimate home arcade. Please use this guide responsibly, as we are strong believers in intellectual property rights and do not advocate copyright infringement in any way. It is the sole responsibility of the developer to obtain any and all rights to use and/or distribute any and all software and related items packaged.

It is the end user's sole responsibility to legally acquire any and all materials for use on a particular emulator. Such as the MAME ROMs that have been approved for free distribution by the MAME organization, please visit https://www.mamedev.org/roms/ . 

## Getting Started
The following sections will prepare your home arcade, as well as the files to be packed into an add-on image.

### Prerequisites
Make sure you have the following ready:

- Arcade console running firmware **3.0.19 or later - last tested with 4.13.0** 
  - Please follow the official OTA upgrade procedure from the user manual to update your firmware to a compatible version
- A USB drive with enough storage to hold your files
  - Please make sure the drive is formatted in FAT(FAT32, exFAT) file system
- Linux users: 
  - Files to be packed into the image (look under "AddOn_Warpspeed" directory)
    - Emulator .so file (LibRetro API emulator core is recommended, *Note: emulator must be compatible with LibRetro APIs*)
    - Game files (Must be compatible with the emulator above)
    - Box art 
    - XML file
    - Script file to execute the game file with the emulator (exec.sh)
- Windows users: look under "AddOn_tool“ directory for the Windows installer and its readme file

### File Structure

Please adhere the following file structure when preparing your add-on image

```
+----------+ 
|   PKG    | <-- name the root directory whatever you want, in the example above,
+---+------+      it would be "AddOn_Warpspeed"
    |
    |   +---------+ 
    +-- |   emu   |  <-- subdirectory for emulators' *.so and config files
    |   +---------+      (for mame2003+, we would need a "retroarch.cfg", "metadata" sub-
    |                    folder, and "mame2003_plus_libretro.so".)
    |
    |   +---------+ 
    +-- |   roms  |  <-- subdirectory for the game files 
    |   +---------+      this example uses "Warpspeed.bin"
    |                    
    |   +---------+ 
    +-- | boxart  |  <-- subdirectory for boxart, "boxart.png" is the default box art image name (222x306).
    |   +---------+      addon.z.png is the default bezel art image name (1280x720).
    |
    |   +---------+ 
    +-- |  save   |  <-- subdirectory for gamesave files
    |   +---------+
    |   
    +--  title       <-- symbolic link to "boxart/boxart.png"
    |   
    +--  cartridge.xml  <-- info header for menu display. *in XML format
    |   
    +--  exec.sh        <-- the script file to run emulator and game files.
                            the example contains:
                            /emulator/retroplayer ./emu/genesis_plus_gx_libretro.so "./roms/Warpspeed.bin"
```
#### Optional: Bezel Art Support

To set a bezel art for the game, add a 1280x720 PNG file under /boxart, name it "addon.z.png".

Then update "exec.sh" to be as follows:

```shell
#!/bin/sh

cp ./boxart/addon.z.png /tmp
echo -e "[Property]\nBezelPath=/tmp/addon.z.png" > /tmp/gameinfo.ini

set -x
/emulator/retroplayer ./emu/genesis_plus_gx_libretro.so "./roms/Warpspeed.bin"

rm -f /tmp/gameingo.ini
```

## Building the Add-on Image

After preparing the files into the structure above, run the following Linux shell script to make a .UCE image file

```shell
build_sq_cartridge_pack.sh ./AddOn_Warpspeed ./AddOn_Warpspeed.UCE
```

The stack inside the Add-on image looks like this:


![Add-on Stack](addOnStack.png)

## Batch Building Images

Use the following steps if you'd like to automate the build process and build many games at once

- prepare the add-on images the same way as before (use the file structure described earlier)
- preferably, make a new directory and move all the add-on directories under it, like so:
```
+----------+ 
|   games  | <-- parent directory
+---+------+      
    |
    |   +---------+ 
    +-- | addOn1  |  <-- game 1
    |   +---------+      
    |     
    |   +---------+ 
    +-- | addOn2  |  <-- game 2
    |   +---------+      
    .
    .
    .
    |   +---------+ 
    +-- | addOnX  |  <-- game X
        +---------+      
```
- make sure the **batch_build.sh** is executable and in the same directory as **build_sq_cartridge_pack.sh** and run the following command 

  - 1st arg is source directory (optional, defaults to pwd)
  - 2nd arg is output directory (optional, defaults to pwd)
  
  ```bash
  ./batch_build.sh ./games 
  ```

- the batch script will go under the source directory and run the build script against each sub-directory
- the output file names will be the same as the sub-directory names

## Playing on the Console

Copy the output Warpspeed.UCE file from the previous section into the root of the USB drive, then insert the drive into either USB slots on the console's control-top. 

Navigate to the BOYG page and the system should automatically load the game(s) if the image is valid.

## FAQs

Q: What's the size limit of the add-on image
> This is limited by the size of the USB drive and the FAT filesystem, it will be automatically mounted by the Linux system and not use any system storage

Q: Will my add-on game saves disappear when I unplug the USB drive?
> The game saves are stored inside the image on the USB drive, not in the console. Therefore they should be there as long as the files on the drive remains intact

Q: I accidentally loaded an incompatible add-on image and my screen turned black, how do I get out of this?
> You should be able to force quit the game by pressing <MENU> button twice. If not then simply power cycle the console and you will be back to the main screen.

Q: Some UCE games crashes my arcade after upgrading to firmware 3.0.11, they used to work before.
> It looks like anti-aliasing is enabled by default for mame2003+ cores, please make sure you use a newer core from libretro to support this option.

Q: I am unable to enter my add-on game after new firmware update, it just takes me back to the menu UI.
> Some mame2003+ ROMs require an empty "hiscore.dat" file under /roms directory for compatibility issues. Please repack your game with the file using Linux script, or repack using the updated Windows tool.
