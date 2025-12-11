#!/bin/bash

# Call the Python script and feed its output into rofi
python3 ~/.config/hypr/Scripts/keyhints.py --format rofi \
  | rofi -p "Keybinds" -dmenu \
    -theme-str 'window { width: 40%; } listview { spacing: 15px; }'
