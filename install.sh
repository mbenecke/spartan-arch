#!/bin/bash

# function
global_settings()  {
    if [ -z "$user" ]; then
        echo "Enter your username: "
        read user
    fi

    if [ -z "$password" ]; then
        echo "Enter your master password: "
        read -s password
    fi
        
    if [ -z "$fast" ]; then
        echo "Do you want to skip rankmirrors (faster upfront)? [y/N] "
        read response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
        then
            fast=1
        else
            fast=0
        fi
    fi
} # END: global_settings

_partition_hd() {
    #partiton disk
    parted --script /dev/sda mklabel msdos mkpart primary ext4 0% 87% mkpart primary linux-swap 87% 100%
    mkfs.ext4 /dev/sda1
    mkswap /dev/sda2
    swapon /dev/sda2
    mount /dev/sda1 /mnt
}
use_virtualbox() {
    
    # set time
    timedatectl set-ntp true

    _partition_hd

    # pacstrap
    pacstrap /mnt base

    # fstab
    genfstab -U /mnt >> /mnt/etc/fstab
    echo "org /home/$user/org vboxsf uid=$user,gid=wheel,rw,dmode=700,fmode=600,nofail 0 0" >> /mnt/etc/fstab
    echo "workspace /home/$user/workspace vboxsf uid=$user,gid=wheel,rw,dmode=700,fmode=600,nofail 0 0" >> /mnt/etc/fstab

    _chroot_install   
   
    # reboot
    umount /mnt
    reboot
} # END: use_virtualbox

use_wsl(){
   _chroot_install
} # END: use_wsl

use_wsl2(){
   _chroot_install
} # END: use_wsl2

use_hyper-v(){
   _chroot_install
} # END: use_hyper-v

_chroot_install(){
    local_cmd=$SHELL
    script='/mnt/chroot-install.sh'
    # chroot
    wget https://raw.githubusercontent.com/mbenecke/spartan-arch/master/chroot-install.sh -O $script
    chmod +x $script
    if [ "$target" == "virtualbox" ]; then
        local_cmd='arch-chroot /mnt /bin/bash'
    fi
    arch-chroot /mnt $local_cmd $script $user $password $fast $target
} # END: _chroot_install

# main

# default
user=""
password=""
fast="y"
target="wsl2"

# arguments                                                      TODO: use getops
user="$1"
password="$2"
fast="$3"
target="$4"

if [ -z "$4" ]; then
    echo "Please chose your target: [1]: VirtualBox; [2]: WSL; [3]: WSL2; [4]: Hyper-V"
    read target
else
    target="$4"
fi
target=$( echo $target | tr '[:upper:]' '[:lower:]' )

case $target in
    "1"|"vbox"|"virtualbox")
        target="virtualbox"
        global_setting
        use_virtualbox
       ;;
    "2"|"wsl")
        target="wsl"
        global_settings
        use_wsl
       ;;
    "3"|"wsl2")
        target="wsl2"
        global_settings
        use_wsl2
       ;;
    "4"|"hyper-v")
        target="hyper-v"
        global_settings
        use_hyper-v
       ;;
    *)
       echo "${target} is not implemented yet, feel free to send a patch" ;;
esac
