# Getting Started
---

``` sh
username: vagrant
password: vagrant
```

## Building the Virtual Machine
1. install `vagrant` on your machine
2. run `run-me` under the project root

this will create the vm. be patient because it takes a bit long. if you want a readily built box, then consider downloading it from Genemek's FTP

currently this project only creates KVM virtual machines. virtualbox and vmware are planned. but if you have kvm/libvirt setup on your machine, you can build it and convert vm image to `.ova` or `.vmdk` formats. further instructions will be provided later.

## First Setup
the `Vagrantfile` contains some vital things for this vm setup but it cannot do further post installation. you'll have to handle it yourself; 

- once you log into vm, open a terminal by hitting `Ctrl + Alt + t` and run `~/run-me`. this will install some packages and setup the environment
- then launch `forticlient` from application menu or from terminal
- setup your credentials and connect to the company VPN service

## Installing Packages
open up `~/.config/home-manager/home.nix` file and add your desired packages here. this is the most clean and reproducible way of installing packages. you can share your configuration with other colleages and they can recreate your system by only using this file. 

once you added your packages save the file and exit. then do `home-manager switch` and packages will be installed

if you don't know what packages are available in `nix` package manager you can simply go to https://search.nixos.org/packages and search packages

if you want to install packages in a traditional `apt-get install` this is also possible but keep in mind you won't remember what you installed in the future and your system might be unstable overtime. try using `home.nix` instead

# Migrating Your System from Virtual Machine to a Physical Disk
---
