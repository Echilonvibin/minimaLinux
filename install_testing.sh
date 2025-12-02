#!/bin/bash

# --- Configuration ---
# Define the list of packages to install using yay to install from AUR
PACKAGES=(
    # Core Components
    polkit-gnome   # PolicyKit authentication agent
    gnome-keyring  # Credential storage  
    hyprlock       # Locks screen, obviously. 
    hypridle       # Turns off screen after set time
    dunst          # Notification daemon
    swaybg         # Simple wallpaper utility (used for setting wallpapers)
    xorg-xwayland  # X11 compatibility layer
    brightnessctl  # Screen control
    pavucontrol    # PulseAudio/PipeWire volume control
    wlsunset       # Nightlight for quickshell

    # User-defined components from README.md
    kitty          # Terminal Emulator
    rofi           # Application Launcher
    fish           # Shell
    fastfetch      # System Info Display
    gedit          # Gnome Advanced Text Editor
    nemo           # File Manager  
    bluez          # Bluetooth utlities
    blueman        # Bluetooth utlities
    upscayl-bin    # Upscaler for images on the fly
    video-downloader # Download videos on your system, avoid sketchy websites! Yipee!
    gnome-calculator # Math n stuff...
    loupe          # image viewer
    gcolor3        # color picker
    protonplus     # proton manager
    
    
    # Bar from noctalia 
    noctalia-shell-git

    #Task Manager, Sleak
    mission-center


)

REPO_DIR=$(pwd)
CONFIG_DIR="$HOME/.config"

# --- Functions ---

# Check if yay is installed, if not, install it
install_yay() {
    if ! command -v yay &> /dev/null; then
        echo "yay not found. Installing yay..."
        sudo pacman -S --needed git base-devel
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        (cd /tmp/yay && makepkg -si --noconfirm)
        rm -rf /tmp/yay
    else
        echo "yay is already installed."
    fi
}

# Deploy configuration files from repo/.config to ~/.config
deploy_configs() {
    echo "Deploying configuration files..."
    
    CONFIG_SOURCE_ROOT="$REPO_DIR/.config"
    
    if [ ! -d "$CONFIG_SOURCE_ROOT" ]; then
        echo "FATAL ERROR: Could not find the '.config' directory inside your repository at '$REPO_DIR'."
        return
    fi

    for component in hypr kitty rofi fastfetch fish; do
        SOURCE_PATH="$CONFIG_SOURCE_ROOT/$component"
        TARGET_PATH="$CONFIG_DIR/$component"
        
        if [ ! -d "$SOURCE_PATH" ]; then
            echo "Error: Source configuration directory '$SOURCE_PATH' not found."
            continue
        fi

        if [ -d "$TARGET_PATH" ] || [ -L "$TARGET_PATH" ]; then
            TIMESTAMP=$(date +%Y%m%d%H%M%S)
            echo "Existing $component config found. Creating backup: $TARGET_PATH.bak.$TIMESTAMP"
            mv "$TARGET_PATH" "$TARGET_PATH.bak.$TIMESTAMP"
        fi
        
        echo "Copying $component configuration: $SOURCE_PATH -> $TARGET_PATH"
        cp -a "$SOURCE_PATH" "$TARGET_PATH"
        
        if [ $? -ne 0 ]; then
            echo "NON-FATAL ERROR: Failed to copy configuration files for $component."
        fi
    done
}

# Deploy files from repo/.local/share to ~/.local/share
deploy_local_share() {
    echo "Deploying local share files..."
    
    LOCAL_SOURCE_ROOT="$REPO_DIR/.local/share"
    LOCAL_TARGET_ROOT="$HOME/.local/share"

    if [ ! -d "$LOCAL_SOURCE_ROOT" ]; then
        echo "No .local/share directory found in repo, skipping..."
        return
    fi

    mkdir -p "$LOCAL_TARGET_ROOT"

    echo "Copying $LOCAL_SOURCE_ROOT -> $LOCAL_TARGET_ROOT"
    cp -a "$LOCAL_SOURCE_ROOT"/* "$LOCAL_TARGET_ROOT"/

    if [ $? -ne 0 ]; then
        echo "NON-FATAL ERROR: Failed to copy files from .local/share."
    fi
}

# Set executable permissions for scripts
set_permissions() {
    SCRIPTS_PATH="$CONFIG_DIR/hypr/Scripts"
    
    if [ -d "$SCRIPTS_PATH" ]; then
        echo "Setting execution permissions for scripts..."
        find "$SCRIPTS_PATH" -type f -exec chmod +x {} \;
    else
        echo "Warning: Hyprland scripts directory '$SCRIPTS_PATH' not found."
    fi
}

# --- Main Installation Flow ---

echo "Starting Hyprland Dotfiles Installation..."

# 1. Install Yay
install_yay

# 2. Install Packages
echo "Installing required packages via yay..."
yay -Syu --noconfirm "${PACKAGES[@]}"

# 3. Deploy Configurations
deploy_configs
deploy_local_share

# 4. Set Script Permissions
set_permissions

echo "Installation complete!"
echo "--------------------------------------------------------"
echo "Next Steps:"
echo "1. Review customization points in README.md."
echo "2. Reboot your system."
echo "3. Select the Hyprland session at your login manager."
echo "--------------------------------------------------------"

