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

echo ".cfg" >> .gitignore
git clone --bare https://git.v7t.de/marco/dotfiles.git $HOME/.cfg
function config {
   /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME $@
}
mkdir -p .config-backup
config checkout
if [ $? = 0 ]; then
  echo "Checked out config.";
  else
    echo "Backing up pre-existing dot files.";
    config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .config-backup/{}
fi;
config checkout
config config status.showUntrackedFiles no

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
    ln -s /mnt/c/Users/marco/_Project ~/_Project
    ln -s /mnt/c/Users/marco/_Area ~/_Area
    ln -s /mnt/c/Users/marco/_Recources ~/_Resources
    ln -s /mnt/c/Users/marco/_Archiv ~/_Archiv
    ln -s /mnt/c/Users/marco/Dropbox/org-folder ~/org
    if [ -d /mnt/c/Users/marco/.emacs.d ]; then
        cp -r /mnt/c/Users/marco/.emacs.d ~/.emacs.d
    fi
    ~/.emacs.d/bin/doom refresh
else 
    mkdir ~/_Project
    mkdir ~/_Area
    mkdir ~/_Resources
    mkdir ~/_Archiv
    mkdir ~/org
    git clone https://github.com/hlissner/doom-emacs ~/.emacs.d
    ~/.emacs.d/bin/doom install
fi

# Initialize keyring
    # This step is necessary for use pacman
    sudo pacman-key --init
    sudo pacman-key --populat

# create tmp and downloads
mkdir -p ~/tmp/downloads
mkdir -p ~/tmp/tools

# xterm setup
echo 'XTerm*background:black' > ~/.Xdefaults
echo 'XTerm*foreground:white' >> ~/.Xdefaults
echo 'UXTerm*background:black' >> ~/.Xdefaults
echo 'UXTerm*foreground:white' >> ~/.Xdefaults

# oh-my-zsh
cd
git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
git clone https://github.com/zsh-autosuggestions ${ZSH-CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
cd ~/tmp/tools/
git clone https://github.com/dracula/zsh.git
cp zsh/dracula.zsh-theme $HOME/.oh-my-zsh/themes/


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
git config --global code.editor emacsclient -n -c
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
go get -u github.com/nsf/gocode
go get -u github.com/rogpeppe/godef
go get -u golang.org/x/tools/cmd/goimports
go get -u github.com/jstemmer/gotags

# X Setup
if [ "$target" == "wsl2" ]; then
    export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2; exit;}'):0.0
    setxkbmap -model pc104 -layout us,de -variant dvorak-intl, -option grp:shifts_toggle -verbose 10  
elif [ "$target" == "virtualbox" ]; then
    # temporary workaround
    cd
    wget https://raw.githubusercontent.com/mbenecke/spartan-arch/master/startx.sh -O startx.sh
    chmod +x startx.sh
    echo 'alias startx=~/startx.sh' >> ~/.zshrc
    ~/startx.sh
fi
