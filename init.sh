#!/bin/bash
set -e

if [ $EUID != 0 ]; then
    echo "Must be root to run this script"
    exit 1
fi

EXECNAME=$0

while [ $# -gt 0 ]; do
    case $1 in
        -d|--drive)
            TGTDRIVE=$2
            shift; shift
            ;;
        -h|--hostname)
            NEWHOSTNAME=$2
            shift; shift
            ;;
        -p|--passwd)
            ROOTPASSWD=$2
            shift; shift
            ;;
        *)
            echo "Usage: $EXECNAME -d|--drive <path/to/hdd> -h|--hostname <new hostname> -p|--passwd <new root passwd>"
            exit 1
    esac
done

[ ! -b "$TGTDRIVE" ] && echo "$TGTDRIVE is not a block device, exiting..." && exit 1

read -p "Are you sure you want to format $TGTDRIVE? (Anything other than 'YES' will cancel): " CONFIRM
if [ $CONFIRM != "YES" ]; then
    echo "Cancelled."
    exit 1
fi

if mount | grep $TGTDRIVE; then
    echo "Cannot proceed because $TGTDRIVE is mounted. Exiting..."
    exit 1
fi

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

echo "Mounting $TGTDRIVE... "
mount ${TGTDRIVE}3 /mnt
mount --mkdir ${TGTDRIVE}4 /mnt/home
mount --mkdir ${TGTDRIVE}1 /mnt/boot
echo "Done."

pacstrap -K /mnt base base-devel linux linux-firmware grub efibootmgr vim

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt bash <<EOF
set -e
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime

hwclock --systohc

sed -i 's/#en_US/en_US/' /etc/locale.gen

locale-gen

echo "LANG=en_US.UTF-8" >> /etc/locale.conf

echo $NEWHOSTNAME > /etc/hosts

echo "root:$NEWPASSWD" | chpasswd

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

grub-mkconfig -o /boot/grub/grub.cfg
EOF

