#!/bin/bash

# Run install.sh first or this will fail due to missing dependencies

user=$1
password=$2
fast=$3
target=$4

# network on boot?
read -t 1 -n 1000000 discard      # discard previous input
if [ "$target" -eq "virtualbox" ]; then
    sudo dhclient enp0s3
    echo 'Waiting for internet connection'
fi

# xinitrc
cd
head -n -5 /etc/X11/xinit/xinitrc > ~/.xinitrc
if [ "$target" == "virtualbox" ]; then
    echo 'exec VBoxClient --clipboard -d &' >> ~/.xinitrc
    echo 'exec VBoxClient --display -d &' >> ~/.xinitrc
fi
echo 'exec i3 &' >> ~/.xinitrc
echo 'exec nitrogen --restore &' >> ~/.xinitrc
echo 'exec emacs' >> ~/.xinitrc

if [ $target == 'hyper-v' ]; then
# https://wiki.archlinux.org/index.php/Hyper-V#Xorg
    cd /tmp
    git clone https://github.com/Microsoft/linux-vm-tools
    cd linux-vm-tools/arch
    ./makepkg.sh
    ./install-config.sh
fi

# emacs config
if [ -d ~/.emacs.d ]; then                             #TODO: Backup, if a directory already exist
    rm -r .emacs.d
fi
if [ target == "wsl2" ]; then                          #TODO: Backup, if a directory already exist
    ln -s /mnt/c/Users/marco/work ~/work
    ln -s /mnt/c/Users/marco/Dropbox/org-folder org

    if [ -d /mnt/c/Users/marco/.emacs.d ]; then
        cp -r /mnt/c/Users/marco/.emacs.d ~/.emacs.d
    fi
    if [ -d /mnt/c/Users/marco/.doom.d ]; then
        cp -r /mnt/c/Users/marco/.doom.d ~/.doom.d
    fi
    ~/.emacs.d/bin/doom refresh
    # Initialize keyring
    # This step is necessary for use pacman
    sudo pacman-key --init
    sudo pacman-key --populat
else 
    git clone https://github.com/hlissner/doom-emacs ~/.emacs.d
    ~/.emacs.d/bin/doom install
fi


# cower & pacaur
mkdir Downloads
cd ~/Downloads
wget https://aur.archlinux.org/cgit/aur.git/snapshot/cower-git.tar.gz
tar -xvf cower-git.tar.gz
cd cower-git
makepkg PKGBUILD
read -t 1 -n 1000000 discard      # discard previous input
sudo pacman -U cower-*.pkg.tar.xz --noconfirm

cd ~/Downloads
wget https://aur.archlinux.org/cgit/aur.git/snapshot/pacaur.tar.gz
tar -xvf pacaur.tar.gz
cd pacaur
makepkg PKGBUILD
read -t 1 -n 1000000 discard      # discard previous input
sudo pacman -U pacaur-*.pkg.tar.xz --noconfirm

# xterm setup
echo 'XTerm*background:black' > ~/.Xdefaults
echo 'XTerm*foreground:white' >> ~/.Xdefaults
echo 'UXTerm*background:black' >> ~/.Xdefaults
echo 'UXTerm*foreground:white' >> ~/.Xdefaults

# tmux setup like emacs
cd
echo 'unbind C-b' > ~/.tmux.conf
echo 'set -g prefix C-x' >> ~/.tmux.conf
echo 'bind C-x send-prefix' >> ~/.tmux.conf
echo 'bind 2 split-window' >> ~/.tmux.conf
echo 'bind 3 split-window -h' >> ~/.tmux.conf

# oh-my-zsh
cd
rm ~/.zshrc -f
git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="bira"/' ~/.zshrc
sed -i 's/plugins=(git)/plugins=(git compleat sudo archlinux emacs autojump common-aliases)/' ~/.zshrc

# environment variable
echo 'export EDITOR=emacsclient' >> ~/.zshrc
echo 'export TERMINAL=lxterminal' >> ~/.zshrc

# i3status
if [ ! -d ~/.config ]; then
    mkdir ~/.config
fi
mkdir ~/.config/i3status
cp /etc/i3status.conf ~/.config/i3status/config
sed -i 's/^order += "ipv6"/#order += "ipv6"/' ~/.config/i3status/config
sed -i 's/^order += "run_watch VPN"/#order += "run_watch VPN"/' ~/.config/i3status/config
sed -i 's/^order += "wireless _first_"/#order += "wireless _first_"/' ~/.config/i3status/config
sed -i 's/^order += "battery 0"/#order += "battery 0"/' ~/.config/i3status/config

# git first time setup
git config --global user.name $(whoami)
git config --global user.email $(whoami)@$(hostname)
git config --global code.editor emacsclient
echo '    AddKeysToAgent yes' >> ~/.ssh/config

# if there are ssh key
if [ -d /mnt/c/Users/marco/.ssh ]; then
    if [ -d ~/.ssh ]; then
        rm -rf ~/.ssh
    fi
    ln -s /mnt/c/Users/marco/.ssh ~/.ssh
fi

# wallpaper setup
cd
mkdir Pictures
cd Pictures
wget http://wallpaperstock.net/canyon-aerial-view-norway-wallpapers_53528_1920x1200.jpg -O wallpaper.jpg
cd ~/.config/
mkdir nitrogen
cd nitrogen
echo '[xin_-1]' > bg-saved.cfg
echo "file=/home/$(whoami)/Pictures/wallpaper.jpg" >> bg-saved.cfg
echo 'mode=0' >> bg-saved.cfg
echo 'bgcolor=#000000' >> bg-saved.cfg

# golang setup
mkdir ~/go
GOPATH=$HOME/go
echo 'export GOPATH=$GOPATH' >> ~/.zshrc
echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.zshrc
go get -u github.com/nsf/gocode
go get -u github.com/rogpeppe/godef
go get -u golang.org/x/tools/cmd/goimports
go get -u github.com/jstemmer/gotags

# X Setup
if [ "$target" == "wsl2" ]; then
    export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2; exit;}'):0.0
    setxkbmap -model pc104 -layout de,us -variant ,dvorak-intl -option grp:shifts_toggle -verbose 10  
elif [ "$target" == "virtualbox" ]; then
    # temporary workaround
    cd
    wget https://raw.githubusercontent.com/mbenecke/spartan-arch/master/startx.sh -O startx.sh
    chmod +x startx.sh
    echo 'alias startx=~/startx.sh' >> ~/.zshrc
    ~/startx.sh
fi
