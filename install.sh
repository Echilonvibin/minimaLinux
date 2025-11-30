#!/bin/bash

# --- Configuration ---
REPO_NAME="echilon-dotfiles"
# Explicitly set the URL for cloning
REPO_URL="https://github.com/Gamma195/$REPO_NAME.git"
INSTALL_DIR="$HOME/Source/$REPO_NAME"
CONFIG_DIR="$HOME/.config"

# Packages required from the official Arch repositories
REQUIRED_PACKAGES=(
    hyprland hyprctl rofi nemo vivaldi code
    grim slurp wayland-protocols wget imagemagick
    fish starship kitty fastfetch
)

# Packages required from the AUR (using yay)
AUR_PACKAGES=(
    noctalia-shell-git
    missioncenter yt-dlp warehouse
    linux-wallpaperengine-git upscaler video-downloader
)

# List of configuration directories/files to back up and link
CONFIG_TARGETS=(
    "hypr"
    "rofi"
    "kitty"
    "fish"
    "starship"
    "fastfetch"
)

# --- Functions ---

# Check for and install yay (AUR helper)
check_and_install_yay() {
    if ! command -v yay &> /dev/null; then
        echo "Yay not found. Installing yay..."

        # Install base-devel and git if not present
        sudo pacman -S --noconfirm base-devel git

        # Clone yay, build, and install
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        (cd /tmp/yay && makepkg -si --noconfirm)
        rm -rf /tmp/yay

        if command -v yay &> /dev/null; then
            echo "Yay installed successfully."
        else
            echo "Error: Failed to install yay. AUR package installation will be skipped."
            return 1
        fi
    else
        echo "Yay is already installed. Skipping installation."
    fi
    return 0
}

# Install necessary packages using pacman and yay
install_packages() {
    echo "--- 1. INSTALLING PACMAN PACKAGES ---"
    sudo pacman -Syu --noconfirm "${REQUIRED_PACKAGES[@]}"

    echo "--- 2. INSTALLING AUR PACKAGES ---"
    if check_and_install_yay; then
        yay -S --noconfirm "${AUR_PACKAGES[@]}"
    fi
}

# Deploy dotfiles, creating backups of existing files
deploy_dots() {
    echo "--- 3. DEPLOYING DOTFILES (CREATING BACKUPS) ---"

    # Clone the repository
    if [ -d "$INSTALL_DIR" ]; then
        echo "Repository already cloned. Skipping clone."
    else
        echo "Cloning $REPO_URL to $INSTALL_DIR..."
        git clone "$REPO_URL" "$INSTALL_DIR"
    fi

    # Create symlinks and backups
    for target in "${CONFIG_TARGETS[@]}"; do
        FULL_PATH="$CONFIG_DIR/$target"

        # CRITICAL: If the target exists (is a file or directory), back it up.
        if [ -d "$FULL_PATH" ] || [ -f "$FULL_PATH" ] || [ -L "$FULL_PATH" ]; then
            # Create a timestamped backup
            TIMESTAMP=$(date +%Y%m%d%H%M%S)
            BACKUP_NAME="$target.bak.$TIMESTAMP"

            echo "-> Backing up existing $target to $BACKUP_NAME"
            mv "$FULL_PATH" "$CONFIG_DIR/$BACKUP_NAME"
        fi

        # Create the new symbolic link
        echo "-> Creating symlink for $target"
        ln -s "$INSTALL_DIR/.config/$target" "$FULL_PATH"
    done

    echo "Dotfiles deployed successfully. Original configs backed up."
}

# Final permission adjustments
set_permissions() {
    echo "--- 4. SETTING SCRIPT PERMISSIONS ---"
    # Set execution permissions for Hyprland scripts
    chmod +x "$CONFIG_DIR/hypr/Scripts/keyhints"
    chmod +x "$CONFIG_DIR/hypr/Scripts/show-keyhints.sh"
    echo "Script permissions set."
}


# --- Main Execution ---

echo "Starting Hyprland Dotfiles Installation..."
echo "=========================================="

install_packages
deploy_dots
set_permissions

echo "=========================================="
echo "Installation Complete!"
echo "Please reboot or log out and select the Hyprland session."
