#!/usr/bin/bash

set -o errexit  # Exit when a command fails
set -o nounset  # Exit when an unset variable is accessed
set -o pipefail # Exit when a command in a pipechain fails 
if [[ "${TRACE-0}" == "1" ]]; then set -o xtrace; fi # Enables debugging through TRACE=1 ./script.sh
cd "$(dirname "$0")"

packages() {
  pacman -Sy grub os-prober doas dhclient wpa_supplicant networkmanager networkmanager-openrc \
            lvm2 lvm2-openrc device-mapper-openrc memtest86+ dosfstools cryptsetup cryptsetup-openrc \
            haveged haveged-openrc device-mapper-openrc cronie cronie-openrc syslog-ng syslog-ng-openrc \
            glibc mkinitcpio
  pacman -Rns artix-grub-theme
}

locale() {
  ln -sf /usr/share/zoneinfo/UTC /etc/localtime
  echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
  locale-gen
  echo "LANG=en_US.utf8" > /etc/locale.conf
  echo "LANGUAGE=en_US" >> /etc/locale.conf
  echo "LC_ALL=C" >> /etc/locale.conf
}

hosts() {
  echo Owl > /etc/hostname
  echo "hostname=Owl" > /etc/conf.d/hostname
  echo "127.0.0.1 localhost" >> /etc/hosts
  echo "::1 localhost" >> /etc/hosts
  echo "127.0.0.1 Owl.localnet Owl" >> /etc/hosts
  passwd
}

mkinit() {
  vim /etc/mkinitcpio.conf
  
  mkinitcpio -p linux-hardened
}

grub() {
  blkid -s UUID -o value /dev/sda1 >> /etc/default/grub
  vim /etc/default/grub
  
  grub-install --target=i386-pc --boot-directory=/boot --bootloader-id=artix --recheck /dev/sda
  grub-mkconfig -o /boot/grub/grub.cfg
  rc-update add device-mapper boot
  rc-update add lvm boot
  rc-update add dmcrypt boot
  rc-update add haveged default
  rc-update add syslog-ng default
}



main() {
  packages
  locale
  hosts
  mkinit
  grub
  
  clear; echo "Now run"; echo "exit"; echo "umount -R /mnt"; echo "sync"; echo "reboot"
}
