#!/bin/bash

#
# v001 - Initial fork.  Removing sudo command for chmod, and putting quotes around "$cart_file" to handle spaces - me-mike
# v002 - Adding checks for required executables, and adding some notes if you don't have them.
#

#Verify all of the executables we need are in our path.  Otherwise exit.
if ! [ -x "$(command -v chmod)" ]; then
  echo 'Error: chmod is not in path.' >&2
  exit 1
fi
if ! [ -x "$(command -v mksquashfs)" ]; then
  echo 'Error: mksquashfs is not in path.' >&2
  exit 1
fi
if ! [ -x "$(command -v dd)" ]; then
  echo 'Error: dd is not in path.' >&2
  exit 1
fi
if ! [ -x "$(command -v md5sum)" ]; then
  echo 'Error: md5sum is not in path.' >&2
  exit 1
fi
if ! [ -x "$(command -v truncate)" ]; then
  echo 'Error: truncate is not in path.' >&2
  exit 1
fi
if ! [ -x "$(command -v mkfs.ext4)" ]; then
  echo 'Error: mkfs.ext4 is not in path.  Requires e2fsprogs package.' >&2
  exit 1
fi
if ! [ -x "$(command -v debugfs)" ]; then
  echo 'Error: debugfs is not in path.  Typically installed to /usr/sbin, so make sure this is in your path.' >&2
  exit 1
fi
if ! [ -x "$(command -v cat)" ]; then
  echo 'Error: cat is not in path.' >&2
  exit 1
fi

echo "All required commands in path"

#cart_file=./byog_cartridge_shfs.img
cart_file=$2
cart_tmp_file=./byog_cartridge_shfs_temp.img
cart_save_file=./byog_cart_saving_ext4.img
squash_mount_point=./squashfs
ext4_saving_mount_point=./saving
 
cart_saving_size=4M
 
if [ -e "$cart_tmp_file" ]; then
    rm -f $cart_tmp_file
fi
 
if [ -e "$cart_save_file" ]; then
    rm -f $cart_save_file
fi
 
#with gzip, block size set as 256K 
chmod 755 $1/exec.sh
mksquashfs $1 $cart_tmp_file -comp gzip -b 262144 -root-owned -nopad
 
SQIMGFILESIZE=$(stat -c%s "$cart_tmp_file")
echo "*** Size of $cart_tmp_file: $SQIMGFILESIZE Bytes (before applying 4k alignment)"
 
 
REAL_BYTES_USED_DIVIDED_BY_4K=$((SQIMGFILESIZE/4096))
if  [ $((SQIMGFILESIZE % 4096)) != 0 ]
then
  REAL_BYTES_USED_DIVIDED_BY_4K=$((REAL_BYTES_USED_DIVIDED_BY_4K+1))
fi
REAL_BYTES_USED=$((REAL_BYTES_USED_DIVIDED_BY_4K*4096))
 
dd if=/dev/zero bs=1 count=$((REAL_BYTES_USED-SQIMGFILESIZE)) >> $cart_tmp_file
 
SQIMGFILESIZE=$(stat -c%s "$cart_tmp_file")
echo "*** Size of $cart_tmp_file: $SQIMGFILESIZE Bytes (after applying 4k alignment)"
 
my_md5string_hex_file=./my_md5string_hex.bin
 
 
# header padding 64 bytes
EXT4FILE_OFFSET=$((SQIMGFILESIZE+64));
echo "*** Offset of Ext4 partition for file saving would be: $EXT4FILE_OFFSET"
 
md5=$(md5sum "$cart_tmp_file" | cut -d ' '  -f 1)
echo "*** SQFS Partition MD5 Hash: "$md5""
echo $md5 | xxd -r -p > $my_md5string_hex_file
dd if=$my_md5string_hex_file of=$cart_tmp_file ibs=16 count=1 obs=16 oflag=append conv=notrunc
dd if=/dev/zero of=$cart_tmp_file ibs=16 count=2 obs=16 oflag=append conv=notrunc
 
if [ -e "$my_md5string_hex_file" ]; then
    rm -f $my_md5string_hex_file
fi
 
truncate -s $cart_saving_size $cart_save_file
mkfs.ext4 $cart_save_file
debugfs -R 'mkdir upper' -w $cart_save_file
debugfs -R 'mkdir work' -w $cart_save_file
 
md5=$(md5sum "$cart_save_file" | cut -d ' '  -f 1)
echo "*** Ext4 Partition MD5 Hash: "$md5""
echo $md5 | xxd -r -p > $my_md5string_hex_file
dd if=$my_md5string_hex_file of=$cart_tmp_file ibs=16 count=1 obs=16 oflag=append conv=notrunc
 
#bind files together
cat $cart_tmp_file $cart_save_file > "$cart_file"
 
if [ -e "$my_md5string_hex_file" ]; then
    rm -f $my_md5string_hex_file
fi
 
if [ -e "$cart_tmp_file" ]; then
    rm -f $cart_tmp_file
fi
 
if [ -e "$cart_save_file" ]; then
    rm -f $cart_save_file
fi
