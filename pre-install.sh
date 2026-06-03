#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "=== Starting Chaotic-AUR Setup ==="

# Retrieve the primary key
echo "-> Fetching the primary key..."
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com

# Locally sign the key
echo "-> Signing the key..."
sudo pacman-key --lsign-key 3056513887B78AEB

# Install the keyring and mirrorlist packages
echo "-> Installing chaotic-keyring and chaotic-mirrorlist..."
sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

# Append the repository to /etc/pacman.conf if it does not already exist
echo "-> Configuring /etc/pacman.conf..."
if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
    sudo tee -a /etc/pacman.conf << 'EOF'

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF
    echo "-> Repository successfully added to configuration."
else
    echo "-> [chaotic-aur] is already present in /etc/pacman.conf. Skipping entry."
fi

# Run a full system update and sync mirrors
echo "-> Running full system upgrade..."
sudo pacman -Syu --noconfirm

echo "=== Chaotic-AUR Setup Complete. ==="
# Install packages needed for my .dotfiles
echo
echo "-> Installing packages . . . "
sudo pacman -S --noconfirm kwin-effect-rounded-corners-git kwin-effects-better-blur-dx klassy-git yay qbittorrent floorp-bin
echo "===  Package installation Complete. ==="
