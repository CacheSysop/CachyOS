#!/bin/bash
sleep 1
# Name of the program to check (e.g., 'myprogram', 'firefox')
PROGRAM_NAME="pia-client"

if ! pgrep "$PROGRAM_NAME" > /dev/null
then
    echo "$PROGRAM_NAME is not running. Starting it now."
    /opt/piavpn/bin/pia-client & # Replace with the actual path and & to run in background
fi
