#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# https://github.com/huandney/fish-pkg-suggest-arch

# Requirements
sudo pacman -S -needed -noconfirm pkgfile expac

fisher install huandney/fish-pkg-suggest-arch

sudo pkgfile -u

sudo systemctl enable --now pkgfile-update.timer
