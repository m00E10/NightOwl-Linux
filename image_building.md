# Pre-chroot
Boot with an Artix USB, login as root and run the following
## Disk Setup
- `pacman -Sy parted vim`
- `parted -s /dev/sdX mklabel msdos`
- `parted -s -a optimal /dev/sdX mkpart "primary" "ext4" "0%" "100%"`
- `parted -s /dev/sdX set 1 boot on`
- `parted -s /dev/sdX set 1 lvm on`

## Luks Encryption Setup 
- `cryptsetup benchmark`
- `cryptsetup --verbose --type luks1 --cipher serpent-xts-plain64 --key-size 512
             --hash whirlpool --iter-time 10000 --use-random 
             --verify-passphrase luksFormat /dev/sdX1`
- `cryptsetup luksOpen /dev/sdX1 lvm-system`
- `pvcreate /dev/mapper/lvm-system`
- `vgcreate lvmSystem /dev/mapper/lvm-system`
- `lvcreate --contiguous y --size 1G lvmSystem --name volBoot`
- `lvcreate --contiguous y --extents +100%FREE lvmSystem --name volRoot`

## Prepare Chroot 
- `mkfs.fat -n BOOT /dev/lvmSystem/volBoot`
- `mkfs.ext4 -L ROOT /dev/lvmSystem/volRoot`
- `mount /dev/lvmSystem/volRoot /mnt`
- `mkdir /mnt/boot`
- `mount /dev/lvmSystem/volBoot /mnt/boot`
- `basestrap /mnt base base-devel openrc elogind-openrc linux-hardened 
                  linux-hardened-headers linux-firmware vim`
- `fstabgen -L /mnt >> /mnt/etc/fstab`
- `artix-chroot /mnt`

# Chroot
## Base Packages
- `pacman -S grub os-prober doas dhclient wpa_supplicant networkmanager  
             networkmanager-openrc lvm2 lvm2-openrc device-mapper-openrc 
             memtest86+ dosfstools cryptsetup cryptsetup-openrc haveged  
             haveged-openrc device-mapper-openrc cronie cronie-openrc   
             syslog-ng syslog-ng-openrc glibc mkinitcpio`
- `pacman -Rns artix-grub-theme` # Shouldn't be installed, but check anyways

## Edit mkinit to support LUKS
Edit the HOOKS line in `/etc/mkinitcpio.conf` to look like the following:
- `HOOKS=(base udev autodetect modconf block encrypt keyboard keymap consolefont lvm2 filesystems fsck)`
- Then run `mkinitcpio -p linux-hardened`

## Edit grub to support LUKS
Edit `/etc/default/grub` to contain the following. Note that "PLACEHOLDER" should be replaced with the output of `blkid -s UUID -o value /dev/sdX1`
```
GRUB_TIMEOUT="15"
GRUB_CMDLINE_LINUX_DEFAULT="cryptdevice=UUID=PLACEHOLDER:lvm-system loglevel=3 quiet net.ifnames=0"
GRUB_ENABLE_CRYPTODISK="y"
GRUB_DISABLE_LINUX_RECOVERY="false"
```
Then run the following
- `grub-install --target=i386-pc --boot-directory=/boot --bootloader-id=artix --recheck /dev/sdX`
- `grub-mkconfig -o /boot/grub/grub.cfg`
- `rc-update add device-mapper boot`
- `rc-update add lvm boot`
- `rc-update add dmcrypt boot`
- `rc-update add haveged default`
- `rc-update add syslog-ng default`

## Locale and Hosts
UTC recommended as it reduces potentially identifiable information
- `ln -sf /usr/share/zoneinfo/UTC /etc/localtime`
- `echo "en_US.UTF-8 UTF-8"   >>  /etc/locale.gen`
- `locale-gen`
- `echo "LANG=en_US.utf8"     >   /etc/locale.conf`
- `echo "LANGUAGE=en_US"      >>  /etc/locale.conf`
- `echo "LC_ALL=C"            >>  /etc/locale.conf`

- `echo Owl                                >  /etc/hostname`
- `echo "hostname=Owl"                     >  /etc/conf.d/hostname`
- `echo "127.0.0.1 localhost"              >> /etc/hosts`
- `echo "::1       localhost"              >> /etc/hosts`
- `echo "127.0.0.1 Owl.localnet Owl"       >> /etc/hosts`

- `passwd`
- `exit`
- `umount -R /mnt`
- `sync`
- `reboot`

# Post Chroot
## Key file to stop double prompts for Encryption password
- `dd bs=512 count=4 if=/dev/urandom of=/keyfile`
- `cryptsetup luksAddKey /dev/sdX1 /keyfile`
Edit your `/etc/mkinitcpio.conf` to contain the following line:
```
FILES=(/keyfile)
```
Then run the following commands
- `mkinitcpio -p linux-hardened`
- `chmod 000 /crypto_keyfile.bin`
- `chmod -R g-rwx,o-rwx /boot`
Append the following to your GRUB_CMDLINE_LINUX line in `/etc/default/grub`:
```
GRUB_CMDLINE_LINUX="... cryptkey=rootfs:/keyfile"
```
Then run `grub-mkconfig -o /boot/grub/grub.cfg`

# Hardening
## Kernel Hardening
- subscripts/sysctl-settings.sh

## Implement Strict Packet Filtering
- subscripts/iptables-for-workstation.sh

## Microcode Hardening
- subscripts/grub-boot-parameters.sh

## Secure Time Sync
- `cd /bin`
- `wget https://gitlab.com/madaidan/secure-time-sync/-/raw/master/secure-time-sync.sh`
- `chmod +x secure-time-sync.sh`
- `crontab -l > cron_bkp`
- `echo \"0 * * * * /bin/secure-time-sync.sh\" >> cron_bkp`
- `crontab cron_bkp`
- `rm cron_bkp`

## Randomize MACs on boot, on scan, and on connection
https://tails.boum.org/contribute/design/MAC_address/
- Edit `/etc/NetworkManager/conf.d/wifi_rand_mac.conf` to have the following
```
[device-mac-randomization]
# "yes" is already the default for scanning
wifi.scan-rand-mac-address=yes
 
[connection-mac-randomization]
# Randomize MAC for every ethernet connection
ethernet.cloned-mac-address=random
# Randomize MAC for every WiFi connection
wifi.cloned-mac-address=random
```
- `echo "scan_ssid=0" >> /etc/NetworkManager/NetworkManager.conf`

## Randomize hostname on boot
- TODO

## Enable Apparmor
- subscripts/apparmor+auditd.sh
- `reboot`
- `apparmor_parser /usr/share/apparmor/extra-profiles/`

# Packages and Services
## Enhance Repos (Optional)
- `echo "universe"                                        >> /etc/pacman.conf`
- `echo "Server = https://universe.artixlinux.org/$arch"  >> /etc/pacman.conf`
- `pacman -Sy artix-archlinux-support`
- `echo "[extra]"                                         >> /etc/pacman.conf`
- `echo "Include = /etc/pacman.d/mirrorlist-arch"         >> /etc/pacman.conf`
- `echo "[community]" 				          >> /etc/pacman.conf`
- `echo "Include = /etc/pacman.d/mirrorlist-arch"         >> /etc/pacman.conf`
- `echo "[multilib]"                                      >> /etc/pacman.conf`
- `echo "Include = /etc/pacman.d/mirrorlist-arch"         >> /etc/pacman.conf`
- `pacman-key --populate archlinux`
- `curl https://blackarch.org/strap.sh | bash`

## Install Night Owl Recommended 
  pacman -Syu base-devel sway wl-clipboard i3status-rust xorg-xwayland \
              man-pages man-db tmux htop tree librewolf noto-fonts     \
              noto-fonts-emoji noto-fonts-extra pipewire pipewire-alsa \
              pipewire-jack pipewire-pulse wireplumber alsa-utils      \
              tor tor-browser torsocks i2pd wireguard-tools            \
              wireguard-openrc yay wget git polkit jq neofetch swaybg  \
              swaylock
  pacman -Rns sudo
  ln -s /usr/bin/doas /usr/bin/sudo
	ln -s /usr/bin/vim /usr/bin/vi
  usermod -a -G video owl

  rc-update add wireguard default

  useradd -m owl
  passwd owl # NightOwl
  echo "permit owl" > /etc/doas.conf
	su owl
	yay -S kickoff
  yay -S krathalans-apparmor-profiles-git
  exit

-- Image to others -----------------------------------------------|
dd if=/dev/wtf of=nightowl.img bs=4M status=progress 
dd if=nightowl.img of=/dev/idk bs=4M status=progress

# After imaging to other USB, expand to use 100% of available space
cryptsetup luksOpen /dev/sdX1 crypt-volume
parted /dev/sda # resizepart NUMBER END
vgchange -a n lvmSystem
cryptsetup luksClose crypt-volume
cryptsetup luksOpen /dev/sda2 crypt-volume
cryptsetup resize crypt-volume
vgchange -a y lvmSystem
pvresize /dev/mapper/crypt-volume # might be lvm-system
lvresize -l+100%FREE /dev/lvmSystem/home
e2fsck -f /dev/mapper/lvmSystem-volRoot
resize2fs /dev/mapper/lvmSystem-volRoot

==[ First Time Setup ]============================================|
 > Make users and passwords # usermod -a -G video $user
   # Download dotfiles: sway .tmux.conf .bashrc .vimrc i3stat kickoff
   ?? Add ^ to /etc/skel ??
 > Change Crypto password # For luks and for /crypto_keyfile.bin
   cryptsetup --verbose open --test-passphrase /dev/sdX1
   cryptsetup luksChangeKey /dev/sdX1 -S Y # Where Y is the slot number shown in the previous command
   
   rm /keyfile
   dd bs=512 count=4 if=/dev/urandom of=/keyfile
   cryptsetup luksAddKey /dev/sdX1 /keyfile
   
