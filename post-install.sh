#!/usr/bin/env fish

sudo pkgfile -u

sudo systemctl enable --now pkgfile-update.timer

omf install lambda

omf theme lambda
