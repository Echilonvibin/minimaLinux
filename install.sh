#!/bin/bash

# --- Configuration ---
# Define the list of packages to install using yay
PACKAGES=(
    # Hyprland and core window management
    hyprland
    hyprlock       # Screen Locker (Added per user request)
    
    # User-defined components from README.md
    kitty          # Terminal Emulator
    rofi           # Application Launcher
    fish           # Shell
    fastfetch      # System Info Display
    
    # Bar from credits (assuming this is an AUR package)
    noctalia-shell-git 
    
    # *** REQUIRED ADDITIONS FOR AUTHENTICATION/CREDENTIALS ***
    polkit-gnome   # PolicyKit authentication agent
    gnome-keyring  # Credential storage
    
    # Example dependencies (adjust as needed)
    dunst          # Notification daemon
    waybar         # Status bar (often used, though you use noctalia-shell-git)
    swaybg         # Simple wallpaper utility (used for setting wallpapers)
    xorg-xwayland  # X11 compatibility layer
    brightnessctl  # Screen control
    pavucontrol    # PulseAudio/PipeWire volume control
    kate           # KDE Advanced Text Editor
    gedit          # GNOME Text Editor
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

# Deploy configuration files
deploy_configs() {
    echo "Deploying configuration files..."
    
    # List of configuration directories in the repository (Source) and their target names (Target)
    # ASSUMPTION: Source directories in the repository are capitalized (e.g., "Hypr")
    #             Target directories in ~/.config must be lowercase (e.g., "hypr")
    
    declare -A component_map=(
        ["Hypr"]="hypr"
        ["Kitty"]="kitty"
        ["Rofi"]="rofi"
        ["Fastfetch"]="fastfetch"
        ["Fish"]="fish"
    )

    for SOURCE_NAME in "${!component_map[@]}"; do
        TARGET_NAME="${component_map[$SOURCE_NAME]}"
        
        SOURCE_PATH="$REPO_DIR/$SOURCE_NAME"
        TARGET_PATH="$CONFIG_DIR/$TARGET_NAME"
        
        # Check 1: Ensure the source directory (in the repo) exists
        if [ ! -d "$SOURCE_PATH" ]; then
            echo "Error: Source configuration directory '$SOURCE_NAME' not found in the repository at '$REPO_DIR'."
            echo "Please ensure the folder '$SOURCE_NAME' exists in your dotfiles repository."
            continue # Skip deployment for this component
        fi

        # Check 2: Backup existing target directory if it exists
        if [ -d "$TARGET_PATH" ] || [ -L "$TARGET_PATH" ]; then
            TIMESTAMP=$(date +%Y%m%d%H%M%S)
            echo "Existing $TARGET_NAME config found. Creating backup: $TARGET_PATH.bak.$TIMESTAMP"
            mv "$TARGET_PATH" "$TARGET_PATH.bak.$TIMESTAMP"
        fi
        
        # Create symbolic link
        echo "Linking $TARGET_NAME configuration: $SOURCE_PATH -> $TARGET_PATH"
        ln -s "$SOURCE_PATH" "$TARGET_PATH"
        
        # Check 3: Check if the linking operation was successful
        if [ $? -ne 0 ]; then
            echo "NON-FATAL ERROR: Failed to create symbolic link for $TARGET_NAME."
            echo "Possible causes: Incorrect permissions on $CONFIG_DIR or target path not writeable. Skipping..."
        fi
    done
}

# Set executable permissions for scripts
set_permissions() {
    # CORRECTED: Uses capitalized 'Scripts'
    SCRIPTS_PATH="$CONFIG_DIR/hypr/Scripts"
    
    # Check if the scripts directory exists before trying to run chmod
    if [ -d "$SCRIPTS_PATH" ]; then
        echo "Setting execution permissions for scripts..."
        # Use find to be robust against hidden files and ensure we only target files
        find "$SCRIPTS_PATH" -type f -exec chmod +x {} \;
    else
        echo "Warning: Hyprland scripts directory '$SCRIPTS_PATH' not found."
        echo "Ensure the 'hypr/Scripts' folder exists in your dotfiles repository."
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

# 4. Set Script Permissions
set_permissions

echo "Installation complete!"
echo "--------------------------------------------------------"
echo "Next Steps (Step 3):"
echo "1. Review customization points in README.md."
echo "2. Reboot your system."
echo "3. Select the Hyprland session at your login manager."
echo "--------------------------------------------------------"
