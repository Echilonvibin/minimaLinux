#!/bin/bash

# --- Configuration ---
# CRITICAL: This MUST match the configuration in install-dots.sh
REPO_NAME="echilon-dotfiles"
INSTALL_DIR="$HOME/Source/$REPO_NAME" # Where the repo was cloned
CONFIG_DIR="$HOME/.config"

# List of configuration directories/files linked by install.sh
CONFIG_TARGETS=(
    "hypr"
    "rofi"
    "kitty"
    "fish"
    "starship"
    "fastfetch"
)

# --- Functions ---

# Function to remove symbolic links and restore original files from backup
remove_symlinks() {
    echo "--- 1. RESTORING CONFIGURATION FILES ---"

    for target in "${CONFIG_TARGETS[@]}"; do
        FULL_PATH="$CONFIG_DIR/$target"

        # Check if the path is a symbolic link pointing to our installation directory
        if [ -L "$FULL_PATH" ] && readlink "$FULL_PATH" | grep -q "$REPO_NAME"; then
            echo "Found symlink for: $target"
            # Remove the symlink
            rm "$FULL_PATH"

            # --- Restoration ---
            # Search for the latest dated backup (e.g., fastfetch.bak.20251130...)
            # We use tail -n 1 to ensure we pick the MOST RECENT backup if multiple exist
            BACKUP_PATH=$(ls -d "$CONFIG_DIR/$target.bak."* 2>/dev/null | tail -n 1)

            if [ -n "$BACKUP_PATH" ]; then
                echo "-> Restoring backup: $(basename "$BACKUP_PATH")"
                # Move the backup back to the original config name
                mv "$BACKUP_PATH" "$FULL_PATH"
            else
                echo "-> No backup found for $target. Leaving directory/file removed."
            fi
        else
            echo "Skipping $target: Not a symlink from this repository or path not found."
        fi
    done

    echo "Symbolic links removed and backups restored (if available)."
}

# Function to delete the dotfiles directory
delete_dotfiles() {
    echo "--- 2. DELETING CLONED REPOSITORY ---"
    echo "Deleting cloned dotfiles directory: $INSTALL_DIR"
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        echo "Successfully deleted $INSTALL_DIR."
    else
        echo "Dotfiles directory not found at $INSTALL_DIR. Skipping."
    fi
}


# --- Main Execution ---

echo "Starting Hyprland Dotfiles Uninstallation..."
echo "============================================"

# 1. Remove the symbolic links and restore backups
remove_symlinks

echo "============================================"

# 2. Delete the cloned dotfiles repository
delete_dotfiles

echo "============================================"
echo "Uninstallation Complete!"
echo ""
echo "--- PACKAGE REMOVAL INSTRUCTIONS ---"
echo "NOTE: This script DOES NOT remove software packages (Hyprland, Kitty, Fish, etc.)"
echo "If you wish to remove the packages installed by the script, please run the following commands manually:"
echo ""
echo "PACMAN PACKAGES:"
echo "sudo pacman -Rns hyprland hyprctl rofi nemo vivaldi code grim slurp wayland-protocols wget imagemagick fish starship kitty fastfetch"
echo ""
echo "AUR PACKAGES (requires yay):"
echo "yay -Rns missioncenter yt-dlp warehouse linux-wallpaperengine-git upscaler video-downloader"
echo ""
echo "You should now log out and select your previous desktop environment."
