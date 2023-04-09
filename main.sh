#!sh

# fmt the hard drive and mount partitions
./init_titan.sh

pacstrap -K /mnt base base-devel linux linux-firmware networkmanager vim

