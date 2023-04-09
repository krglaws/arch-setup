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

ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime

hwclock --systohc

sed -i 's/#en_US/en_US/' /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" >> /etc/locale.conf

get_input_confirm "HOSTNAME" "hostname"

echo $HOSTNAME > /etc/hosts

get_input_confirm "NEWPASSWD" "password"

echo "root:$NEWPASSWD" | chpasswd

