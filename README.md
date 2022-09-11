# NightOwl-Linux
Minimal and hardened linux for on the go secure communications, based on Artix

This is an .img based installation that can be written to flash drives or hard drives

At the moment consider this a pre-alpha. Image building is not yet automated

TODO:
 - Maintain select AppArmor profiles (such as for Librewolf)
 - Maintain Arch repo containing select packages to avoid using AUR during updates (such as for kickoff)
 - Fix profile located at /usr/share/apparmor/extra-profiles/usr.bin.man
 - Write openrc bootlevel script to randomize hostname from a list of natural sounding hosts
 - Run a first time setup when image is first booted, change user password, root password, make unprivd user, change cryptodisk pass
 - Add a "Features" section to the Readme 
