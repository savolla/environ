#!/usr/bin/env bash

export NIXPKGS_ALLOW_UNFREE=1

sudo dnf update -y
sudo dnf install -q -y unclutter-xfixes \
  screenkey \
  udiskie \
  mpd \
  picom \
  uv \
  lxsession \
  curl \
  fuse-libs \
  blender \
  transmission-gtk \
  mpc \
  shellcheck \
  xclip \
  ncmpcpp \
  sxhkd \
  feh \
  fzf \
  flameshot \
  wipe \
  lxappearance \
  git \
  bat \
  zsh \
  unrar \
  dunst \
  gcolor3 \
  xcalib \
  peek \
  neovim \
  tmux \
  ranger \
  kitty \
  gdu \
  gnome-tweaks \
  mpv \
  tldr \
  gparted \
  pcmanfm \
  codium \
  distrobox \
  chromium \
  brave-browser \
  firefox \
  lutris \
  steam \
  xorg-x11-server-Xorg \
  gnome-session-xsession \
  xdotool

# virtualization
sudo dnf install @virtualization -y
sudo dnf install virt-install virt-viewer -y

# change default shell for user
grep -q "zsh" /etc/shells || sudo sh -c 'echo "/usr/bin/zsh" >> /etc/shells'
chsh -s /usr/bin/zsh

# install starship
curl -sS https://starship.rs/install.sh | sh -s -- -y

# detect GPU and install appropriate drivers
gpu_info=$(lspci | grep -i 'vga\|3d')

if echo "$gpu_info" | grep -iq 'nvidia'; then
  echo "NVIDIA GPU detected. Installing NVIDIA drivers..."
  sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
  sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
  sudo dnf install -y akmod-nvidia
  sudo dnf install -y xorg-x11-drv-nvidia-cuda
elif echo "$gpu_info" | grep -iq 'amd\|ati'; then
  echo "AMD GPU detected. Installing AMD drivers..."
  sudo dnf install -y xorg-x11-drv-amdgpu
else
  echo "No NVIDIA or AMD GPU detected. Using default drivers."
fi

# compile suckless utilities
sudo dnf install -y \
  libX11-devel \
  libXft-devel \
  libXinerama-devel \
  freetype-devel \
  fontconfig-devel \
  libXrandr-devel \
  make

cd ~/project/suckless/dmenu-5.3 || exit
sudo make install
make clean
cd ~/project/suckless/dwm-6.5 || exit
sudo make install
make clean
cd ~/project/suckless/slock-1.5 || exit
sudo make install
make clean
cd ~/project/suckless/st-0.9.2 || exit
sudo make install
make clean
cd ~/project/suckless/slstatus || exit
sudo make install
make clean

# enable dwm option in gdm
sudo touch /usr/share/xsessions/dwm.desktop
sudo chmod +x /usr/share/xsessions/dwm.desktop
sudo bash -c "cat << EOF > /usr/share/xsessions/dwm.desktop
[Desktop Entry]
Name=DWM
Comment=Dynamic Window Manager
Exec=dwm
Icon=dwm
Type=Application
DesktopNames=DWM
X-GDM-SessionType=x11
EOF"

# doom emacs install
git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
~/.config/emacs/bin/doom install
~/.config/emacs/bin/doom sync

# install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts

# setup nix
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --no-daemon
. /home/savolla/.nix-profile/etc/profile.d/nix.sh

# update font cache
fc-cache -fv

# install nix packages that fedora does not include
nix-env -iA nixpkgs.eza
nix-env -iA nixpkgs.fd
nix-env -iA nixpkgs.xcolor
nix-env -iA nixpkgs.emacs-gtk
nix-env -iA nixpkgs.ferdium
nix-env -iA nixpkgs.librewolf-bin
nix-env -iA nixpkgs.logseq
nix-env -iA nixpkgs.xsct       # redshift but good
nix-env -iA nixpkgs.devilspie2 # for placing specific programs on their specific workspaces in gnome
nix-env -iA nixpkgs.keepassxc
nix-env -iA nixpkgs.libtool # vterm dep
nix-env -iA nixpkgs.cmake   # doom vterm compilation dep
nix-env -iA nixpkgs.unp   # extract archives all in one
nix-env -iA nixpkgs.mermaid-cli   # mermaid compiler (org-mode)
nix-env -iA nixpkgs.nsxiv   # image viewer
nix-env -iA nixpkgs.drawio # draw diagrams

## DEVOPS MODULE
# IaC
nix-env -iA nixpkgs.terraform
nix-env -iA nixpkgs.terraform-ls  # for doom emacs terraform lang server
nix-env -iA nixpkgs.terraformer # infrastructure to code (reverse terraform)
nix-env -iA nixpkgs.terraform-local # use terraform with localstack
nix-env -iA nixpkgs.cloud-init  # provision images with terraform
sudo dnf install ansible -q -y # get ansible
sudo dnf install dot -q -y # for terraform graph visualization

# Conteainerization
# docker
# add docker repo
sudo dnf -y install dnf-plugins-core
sudo dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
# install docker and deps
sudo dnf install -y -q docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# add user to docker group
sudo usermod -aG docker "$USER"
# start docker service
sudo systemctl enable --now docker

# AWS
sudo dnf install -q -y awscli2

# localstack
# nix-env -iA nixpkgs.localstack # commented bc I installed it manually for the most up to date version. nix installs old version
