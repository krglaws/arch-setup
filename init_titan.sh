#!/bin/sh
# Boot into arch ISO, run this script to format and mount target drive

set -e

SFDISKCMDS="label=gpt
,1GiB,uefi
,8GiB,swap
,100GiB
,
"

if [ $EUID != 0 ]
then
    echo "Must be root to run this script"
    exit 1
fi

read -p "Enter the path to target hard drive: " TGTDRIVE
read -p "Re-enter the path to confirm: " TGTDRIVECONF

if [ "$TGTDRIVE" != "$TGTDRIVECONF" ]
then
    echo "The paths do not match, exiting..."
    exit 1
fi

read -p "Are you sure you want to format $TGTDRIVE? (Anything other than 'YES' will cancel): " CONFIRM
if [ $CONFIRM != "YES" ]
then
    echo "Cancelled."
    exit 1
fi

echo "Formatting..."
echo "$SFDISKCMDS" | sfdisk $TGTDRIVE
mkfs.fat -F 32 ${TGTDRIVE}1
mkswap ${TGTDRIVE}2
swapon ${TGTDRIVE}2
mkfs.ext4 ${TGTDRIVE}3
mkfs.ext4 ${TGTDRIVE}4
echo "Done."

echo "Mounting $TGTDISK... "
mount ${TGTDRIVE}3 /mnt
mount --mkdir ${TGTDRIVE}4 /mnt/home
mount --mkdir ${TGTDRIVE}1 /mnt/boot
echo "Done."


