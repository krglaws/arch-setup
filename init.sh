#!/bin/bash

set -e

################################
# Functions and argument parsing
# ------------------------------

if [ $EUID != 0 ]; then
    echo "Must be root to run this script"
    exit 1
fi

EXECNAME=$0

error_msg() {
    echo $@ >&2
    exit 1
}

usage() {
    error_msg "Usage: $EXECNAME -d <path/to/drive> -n <new hostname> -p <new root password> -u <admin username>"
}

while [ $# -gt 0 ]; do
    case $1 in
        -d)
            TGTDRIVE=$2
            shift; shift
            ;;
        -n)
            NEWHOSTNAME=$2
            shift; shift
            ;;
        -p)
            ROOTPASSWD=$2
            shift; shift
            ;;
        -u)
            ADMINUSER=$2
            shift; shift
            ;;
        *)
            usage
            ;;
    esac
done


############################################
# Validate args and make sure we can proceed
# ------------------------------------------

[ -z "$TGTDRIVE" -o -z "$NEWHOSTNAME" -o -z "$ROOTPASSWD" ] && usage
[ ! -b "$TGTDRIVE" ] && error_msg "'$TGTDRIVE' is not a block device."
read -p "Are you sure you want to format $TGTDRIVE? (Anything other than 'YES' will cancel): " CONFIRM
if [ $CONFIRM != "YES" ]; then
    error_msg "Cancelled."
fi
if mount | grep $TGTDRIVE; then
    error_msg "Cannot proceed because $TGTDRIVE is mounted. Exiting..."
fi


#############################
# Script actually starts here
# ---------------------------

swapoff --all

sfdisk $TGTDRIVE <<EOF
label: gpt
,1GiB,uefi
,8GiB,swap
,50GiB
,
EOF

mkfs.fat -F 32 ${TGTDRIVE}1
mkswap ${TGTDRIVE}2
swapon ${TGTDRIVE}2
mkfs.ext4 ${TGTDRIVE}3
mkfs.ext4 ${TGTDRIVE}4
mount ${TGTDRIVE}3 /mnt
mount --mkdir ${TGTDRIVE}4 /mnt/home
mount --mkdir ${TGTDRIVE}1 /mnt/boot

#pacstrap -K /mnt base base-devel linux linux-firmware grub efibootmgr vim man-db man-pages
pacstrap -K /mnt - <<EOF
archlinux-keyring
bash
bzip2
coreutils
file
filesystem
findutils
gawk
gcc-libs
gettext
glibc
grep
gzip
iproute2
iputils
licenses
pacman
pciutils
procps-ng
psmisc
sed
shadow
tar
util-linux
xz
linux
linux-firmware
grub
efibootmgr
man-db
man-pages
base-devel
git
vim
EOF

genfstab -U /mnt >> /mnt/etc/fstab
echo "nameserver 8.8.8.8 1.1.1.1" >> /mnt/etc/resolv.conf

arch-chroot /mnt bash <<EOF
set -e
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime

hwclock --systohc

sed -i 's/#en_US/en_US/' /etc/locale.gen

locale-gen

echo "LANG=en_US.UTF-8" >> /etc/locale.conf

echo $NEWHOSTNAME > /etc/hostname

echo "root:$ROOTPASSWD" | chpasswd

groupadd -r sudo
useradd -m $ADMINUSER -G sudo

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

grub-mkconfig -o /boot/grub/grub.cfg
EOF

