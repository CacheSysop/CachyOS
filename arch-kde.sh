#!/usr/bin/env bash
set -euo pipefail

(( EUID == 0 )) || {
    echo "Run with: sudo $0"
    exit 1
}

echo "==> Updating system"
pacman -Syu --noconfirm

echo "==> Making Dolphin actually feel complete"
pacman -S --needed --noconfirm \
    dolphin \
    dolphin-plugins \
    kio-admin \
    kio-extras \
    kio-fuse \
    ffmpegthumbs \
    kdegraphics-thumbnailers \
    kdenetwork-filesharing \
    ark \
    filelight

echo "==> KDE desktop integration"
pacman -S --needed --noconfirm \
    kde-cli-tools \
    kdeconnect \
    kde-gtk-config \
    kimageformats \
    qt6-imageformats \
    plasma-browser-integration \
    partitionmanager

echo "==> Useful KDE applications"
pacman -S --needed --noconfirm \
    kate \
    konsole \
    gwenview \
    okular \
    spectacle \
    kcalc

echo "==> CLI quality-of-life"
pacman -S --needed --noconfirm \
    nano \
    bash-completion \
    man-db \
    man-pages \
    ripgrep \
    fd \
    wget \
    curl \
    git \
    unzip

echo "==> Nano quality-of-life"

mkdir -p /etc/nanorc.d

cat >/etc/nanorc.d/arch-enhancements.nanorc <<'EOF'
set linenumbers
set tabsize 4
set tabstospaces
set autoindent
set indicator
set minibar
set stateflags
set zap
include "/usr/share/nano/*.nanorc"
EOF

echo
echo "==> KDE enhancements installed."
echo "Log out/in before judging desktop integration."
