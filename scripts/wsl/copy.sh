#!/usr/bin/env bash
#PATHS - -config
WSL_SOURCE="$HOME/DashcamMedia"

#hardcoded user && dirs 
WIN_USER="gregg"

WIN_TARGET="/mnt/c/Users/$WIN_USER/Videos/Dash"

# file copy 
echo "Exporting dashcam videos to Windows folder..."

# create target dir if it doesn't exist
mkdir -p "$WIN_TARGET"

#copy all from WSL dir /DashcamMedia into Windows for wasy viewing
cp -r "$WSL_SOURCE"/* "$WIN_TARGET/"

if [[ $? -eq 0 ]]; then
    echo "[SUCCESS] Dashcam videos copied to: $WIN_TARGET"
    echo "C:\\Users\\$WIN_USER\\Videos\\Dash"
else # fuck
    echo "[ERROR] Copy failed. Please check source and destination paths."
fi
