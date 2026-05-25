#!/usr/bin/env fish

# Exit immediately if a command exits with a non-zero status
set -e


sudo pkgfile -u

sudo systemctl enable --now pkgfile-update.timer

omf install lambda

omf theme lambda
