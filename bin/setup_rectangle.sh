#!/bin/bash

# Stages the Rectangle config for import. Rectangle reads
# ~/Library/Application Support/Rectangle/RectangleConfig.json once on launch,
# then renames it (live settings are NSUserDefaults) — so re-run this script
# and relaunch Rectangle to apply hotkey changes from etc/RectangleConfig.json.

DOTFILES="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
DEST="$HOME/Library/Application Support/Rectangle"

mkdir -p "$DEST"
cp -v "$DOTFILES/etc/RectangleConfig.json" "$DEST/RectangleConfig.json"

if pgrep -xq Rectangle; then
    killall Rectangle
    open -a Rectangle
    echo "Rectangle relaunched — config imported."
else
    echo "Config staged — Rectangle will import it on next launch."
fi
