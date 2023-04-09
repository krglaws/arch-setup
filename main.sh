#!/bin/bash
set -e

get_input_confirm() {
    VARNAME=$1
    PROMPTNAME=$2
    while [ -z ${!VARNAME} ]; do
        read -p "Enter $PROMPTNAME: " $VARNAME
        read -p "Re-enter $PROMPTNAME: " VARNAMECONF
        if [ "${!VARNAME}" != "${VARNAMECONF}" ]; then
            unset $VARNAME
            echo "${PROMPTNAME}s do not match, try again"
        fi
    done
}

SFDISKCMDS="label: gpt
,1GiB,uefi
,8GiB,swap
,100GiB
,
"

if [ $EUID != 0 ]; then
    echo "Must be root to run this script"
    exit 1
fi

get_input_confirm TGTDRIVE "path to target drive"
get_input_confirm NEWHOSTNAME "new hostname"
get_input_confirm NEWPASSWD "new password"

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

pacstrap -K /mnt base base-devel linux linux-firmware grub networkmanager vim

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

