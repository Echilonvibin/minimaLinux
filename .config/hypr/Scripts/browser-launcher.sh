#!/bin/bash

for b in brave firefox zen-browser vivaldi; do
    if command -v "$b" >/dev/null 2>&1; then
        exec "$b" "$@"
        exit 0
    fi
done

# If nothing found
notify-send "No browser found" "Install Brave, Firefox, Zen Browser or Vivaldi."
