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
    pacman -S grub --noconfirm
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
    pacman -S --noconfirm mkinitcpio
fi
mkinitcpio -p linux

_setup_mirror $fast 
_setup_timezone
_setup_hostname
_install_bootloader

# install Xorg
echo 'Installing Xorg'
pacman -S --noconfirm xorg xorg-xinit xterm

if [ "$target" == "virtualbox" ]; then
    # install virtualbox guest modules
    echo 'Installing VB-guest-modules'
    pacman -S --noconfirm virtualbox-guest-modules-arch virtualbox-guest-utils

    # vbox modules
    echo 'vboxsf' > /etc/modules-load.d/vboxsf.conf
fi

# install dev envt.
echo 'Installing dev environment'
pacman -S --noconfirm git emacs zsh nodejs npm vim wget perl make gcc grep tmux i3 dmenu
pacman -S --noconfirm chromium curl openssh sudo mlocate the_silver_searcher
pacman -S --noconfirm ttf-hack lxterminal nitrogen ntp dhclient keychain
pacman -S --noconfirm python-pip go go-tools pkg-config base-devel htop
# https://martin.leyrer.priv.at/downloads/talks/2019/gpn19%20-%20Moderne%20Kommandozeilentools%20published.pdf
pacman -S --noconfirm aria2c bind-tools mtr liboping ranger jqv colordiff fd exa fzf pv progress 
pacman -S --noconfirm lynis nethogs nmon reptyr
#do a Installation from the package.txt, which is a clone from a golden source
wget https://raw.githubusercontent.com/mbenecke/spartan-arch/master/packages.txt -o /home/$user/package.txt
pacman -S --needed --noconfirm < /home/$user/packages.txt
npm install -g jscs jshint bower grunt
pip install pipenv bpython ipython
pip install pytest nose black pyflakes isort 

# install req for pacaur & cower
echo 'Installing dependencies'
pacman -S --noconfirm expac fakeroot yajl openssl

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
