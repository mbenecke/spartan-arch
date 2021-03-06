# spartan-arch

This is a set of scripts designed to automate the creation of a minimal VM
running Arch Linux and i3/Emacs as a Windows manager. This VM can be used as a
file editor for the host via folder sharing and as a development environment.
Currently, the VM costs about 90MB of RAM to run.

## Requirements for Virtual Box VM
- 8GB of space on disk
- 1GB of RAM
- Clipboard sharing in both directions enabled
- Two shared folders `org` and `workspace` auto-mount and permanent

## Pacman Package List

Generate by:
```shell
pacman -Qqn > package.txt
```
Foreign (AUR) packages must be reinstalled separately; you can list them with:
```shell
pacman -Qqm > packaur.txt
```


## Installation
Boot the VM on archlinux iso and then run the command
```shell
wget https://url.v7t.de/W -O install.sh
$SHELL install.sh [user] [password] [fast]
```
All arguments are optional and will be prompted for if not passed on invocation:
- `[user]` is your username
- `[password]` is what you want the root and user password to be
- `[fast]` is boolean 1 or 0 and controls using `rankmirrors` during set up
  which will be slow
- `[target]` is optional to switch between VirtualBox or WSL2 Installations

The install.sh script will run and then reboot the computer once done.

You want to boot on disk this time and eject the cd from the VM.

Login as your user then run the command
```shell
bash post-install.sh
```
The script will ask for the root password a couple of times.

## Usage
Once the VM is booted, log in as your user and call `startx` to start Xorg.

## TODO
- dhcpcd on boot
- ssh-keys generation
