#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define the source directory (dotfiles folder in the current directory)
SRC_DIR="./dotfiles"
DEST_DIR="$HOME"

# Check if the dotfiles directory actually exists
if [ ! -d "$SRC_DIR" ]; then
    echo "Error: '$SRC_DIR' directory not found!"
    exit 1
fi

echo "Moving hidden files and folders from $SRC_DIR to $DEST_DIR..."

# Enable dotglob so * matches hidden files
shopt -s dotglob

# Move everything from the dotfiles folder to the home directory
mv "$SRC_DIR"/* "$DEST_DIR/"

# Disable dotglob to return the shell to its default behavior
shopt -u dotglob

echo "Done! Dotfiles successfully moved."
