#!/usr/bin/env bash

SRC_DIR="./dotfiles"
DEST_DIR="$HOME"

# Check if the dotfiles directory exists
if [ ! -d "$SRC_DIR" ]; then
    echo "Error: '$SRC_DIR' directory not found!"
    exit 1
fi

echo "Copying and overwriting dotfiles to $DEST_DIR..."

# -a: archive mode (preserves permissions, timestamps, symlinks)
# -v: verbose (shows you exactly what is being overwritten)
# --overwrite: forces rsync to overwrite existing files/directories smoothly
rsync -av "$SRC_DIR/" "$DEST_DIR/"

echo "Done! Dotfiles successfully merged and overwritten in your home directory."
