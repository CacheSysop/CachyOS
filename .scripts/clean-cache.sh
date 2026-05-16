#!/bin/sh


echo Clean package cache: keep last 3 versions of installed packages.
sudo paccache -rk3
echo
echo Remove all cached files for uninstalled packages.
sudo paccache -ruk0
