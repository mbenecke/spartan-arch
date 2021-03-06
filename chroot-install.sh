#!/bin/bash

# This will be ran from the chrooted env.

user=$1
password=$2
fast=$3
target=$4

_setup_timezone() {
    # setup timezone
    echo 'Setting up timezone'
    timedatectl set-ntp true
    ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime
    timedatectl set-timezone Europe/Berlin
    hwclock --systohc  
}

_setup_mirror() {
    # setup mirrors
    fast=0
    if [ ! -z $1 ]; then
        fast=$1
    fi
    if [ "$fast" -eq "0" ]; then
        echo 'Setting up mirrors'
        cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
        sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist.backup
        rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist
    else
        echo 'Skipping mirror ranking because fast'
    fi
}

_setup_hostname() {
    # setup hostname
    echo 'Setting up hostname'
    echo 'arch-virtualbox' > /etc/hostname
}

_install_bootloader() {
    # install bootloader
    echo 'Installing bootloader'
    pacman -S grub --needed --noconfirm
    grub-install --target=i386-pc /dev/sda
    grub-mkconfig -o /boot/grub/grub.cfg
}

# setup locale
echo 'Setting up locale'
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
sed -i 's/^#de_DE.UTF-8/de_DE.UTF-8/' /etc/locale.gen
locale-gen
# German locale with English messages
echo 'LANG=de_DE.UTF-8' > /etc/locale.conf
echo 'LC_MESSAGES=en_US.UTF-8' >> /etc/locale.conf

echo 'KEYMAP=dvorak' > /etc/vconsole.conf

pacman -Syyu --noconfirm 

# build
echo 'Building'
if [ ! -f /usr/bin/mkinitcpio ]; then
    pacman -S --needed --noconfirm mkinitcpio
fi
mkinitcpio -p linux

_setup_mirror $fast 
_setup_timezone
_setup_hostname
_install_bootloader

# install Xorg
echo 'Installing Xorg'
pacman -S --needed --noconfirm xorg xorg-xinit xterm

if [ "$target" == "virtualbox" ]; then
    # install virtualbox guest modules
    echo 'Installing VB-guest-modules'
    pacman -S --needed --noconfirm virtualbox-guest-modules-arch virtualbox-guest-utils

    # vbox modules
    echo 'vboxsf' > /etc/modules-load.d/vboxsf.conf
fi

# install dev envt.
echo 'Installing dev environment'
pacman -S --needed --noconfirm git emacs zsh nodejs npm vim wget perl make gcc grep tmux i3 dmenu
pacman -S --needed --noconfirm chromium curl openssh sudo mlocate the_silver_searcher
pacman -S --needed --noconfirm ttf-hack lxterminal nitrogen ntp dhclient keychain
pacman -S --needed --noconfirm python-pip go go-tools pkg-config base-devel htop
# https://martin.leyrer.priv.at/downloads/talks/2019/gpn19%20-%20Moderne%20Kommandozeilentools%20published.pdf
pacman -S --needed --noconfirm aria2c bind-tools mtr liboping ranger jqv colordiff fd exa fzf pv progress 
pacman -S --needed --noconfirm lynis nethogs nmon reptyr broot
#do a Installation from the package.txt, which is a clone from a golden source
wget https://raw.githubusercontent.com/mbenecke/spartan-arch/master/packages.txt -o /home/$user/package.txt
<<<<<<< HEAD
pacman -S --needed --noconfirm < /home/$user/packages.txt

#Install https://aur.archlinux.org/packages/pacaur/
cd /usr/src
git clone https://aur.archlinux.org/pacaur.git
cd pacaur
makepkg -si



=======
pacman -S --needed $(comm -12 <(pacman -Slq | sort) <(sort /home/$user/packages.txt))

chgrp nobody /usr/src
chmod g+ws /usr/src
setfacl -m u::rwx,g::rwx /usr/src
setfacl -d --set u::rwx,g::rwx,o::- /usr/src
cd /usr/src
https://aur.archlinux.org/auracle-git.git
cd /usr/src/auracle-git
sudo -u nobody makepkg -si
https://aur.archlinux.org/pacaur.git
cd /usr/src/pacaur
sudo -u nobody makepkg -si
wget https://raw.githubusercontent.com/mbenecke/spartan-arch/master/packaur.txt -o /home/$user/packaur.txt
pacaur -S --needed --noconfirm --noedit $( sort /hom/$user/packaur.txt)
>>>>>>> origin/master

npm install -g jscs jshint bower grunt
pip install pipenv bpython ipython
pip install pytest nose black pyflakes isort 

# install req for pacaur & cower
echo 'Installing dependencies'
pacman -S --needed --noconfirm expac fakeroot yajl openssl

# user mgmt
echo 'Setting up user'
read -t 1 -n 1000000 discard      # discard previous input
echo 'root:'$password | chpasswd
useradd -m -G wheel -s /bin/zsh $user
touch /home/$user/.zshrc
chown $user:$user /home/$user/.zshrc
mkdir /home/$user/org
chown $user:$user /home/$user/org
mkdir /home/$user/workspace
chown $user:$user /home/$user/workspace
echo $user:$password | chpasswd
echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers

# enable services
systemctl enable ntpdate.service

# preparing post install
wget https://raw.githubusercontent.com/mbenecke/spartan-arch/master/post-install.sh -O /home/$user/post-install.sh 
chown $user:$user /home/$user/post-install.sh

echo 'Done'
