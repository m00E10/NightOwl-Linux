#!/usr/bin/bash

set -o errexit  # Exit when a command fails
set -o nounset  # Exit when an unset variable is accessed
set -o pipefail # Exit when a command in a pipechain fails 
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi # Enables debugging through TRACE=1 ./script.sh
cd "$(dirname "$0")"

partitions() {
  pacman -Sy parted vim glibc
  
  clear; lsblk ; echo "What disk would you like to install Night Owl to?"
  read DISK
  
  parted -s /dev/$DISK mklabel msdos
  parted -s -a optimal /dev/$DISK mkpart "primary" "ext4" "0%" "100%"
  parted -s /dev/$DISK set 1 boot on
  parted -s /dev/$DISK set 1 lvm on
}

luks() {
  cryptsetup benchmark
  cryptsetup --verbose --type luks1 --cipher serpent-xts-plain64 --key-size 512 --hash whirlpool \
             --iter-time 10000 --use-random --verify-passphrase luksFormat /dev/$DISK\1
  cryptsetup luksOpen /dev/$DISK\1 lvm-system
  pvcreate /dev/mapper/lvm-system
  vgcreate lvmSystem /dev/mapper/lvm-system
  lvcreate --contiguous y --size 1G lvmSystem --name volBoot
  lvcreate --contiguous y --extents +100%FREE lvmSystem --name volRoot
}

filesystems() {
  mkfs.fat -n BOOT /dev/lvmSystem/volBoot
  mkfs.ext4 -L ROOT /dev/lvmSystem/volRoot
  mount /dev/lvmSystem/volRoot /mnt
  mkdir /mnt/boot
  mount /dev/lvmSystem/volBoot /mnt/boot
  basestrap /mnt base base-devel openrc elogind-openrc linux-hardened linux-hardened-headers linux-firmware vim
  fstabgen -L /mnt >> /mnt/etc/fstab
}

partitions
luks
filesystems

mv chroot.sh /mnt
clear; echo "Now run bash chroot.sh"
artix-chroot /mnt
