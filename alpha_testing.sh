#!/bin/bash

export LC_MESSAGES=C
export LANG=C

# --- Pre-flight confirmation ---
echo "This script will install custom dot-files for Hyprland and the Chaotic AUR. Use only with fresh install of Hyprland (Vanilla Arch Linux only). Use at your own risk."
while true; do
    read -r -p "Would you like to proceed? (y/n): " proceed
    case "$proceed" in
        y|Y|yes|YES)
            echo "Great! Proceeding with installation..."
            break
            ;;
        n|N|no|NO)
            echo "Fair enough, Have a nice day."
            exit 0
            ;;
        *)
            echo "Please answer 'y' or 'n'."
            ;;
    esac
done

# Ensure running as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root." >&2
  exit 1
fi

if [ ! -f /etc/pacman.conf ]; then
  echo "File [/etc/pacman.conf] not found!"
  exit 1
fi

# --- Configuration ---
# Get the actual user running the script (not root)
if [ -n "$SUDO_USER" ]; then
    ACTUAL_USER="$SUDO_USER"
else
    ACTUAL_USER=$(who | awk '{print $1}' | head -n 1)
fi
ACTUAL_USER_HOME=$(eval echo ~$ACTUAL_USER)

# Define the list of packages to install using pacman
PACKAGES=(
    # Core Components
    polkit-gnome              # PolicyKit authentication agent
    gnome-keyring             # Credential storage  
    hyprlock                  # Locks screen, obviously. 
    hypridle                  # Turns off screen after set time
    pavucontrol               # PulseAudio/PipeWire volume control
    wlsunset                  # Nightlight for quickshell
    fish                      # Shell
    fastfetch                 # System Info Display
    bluez                     # Bluetooth utilities
    bluez-utils               # Bluetooth utilities
    blueman                   # Bluetooth manager
    satty                     # Screenshot annotation tool
    grim                      # Screenshot utility for wayland
    slurp                     # Screenshot selector for region
    hyprshot                  # Screenshot selector region - this is a standalone app
    gedit                     # Gnome Advanced Text Editor
    nwg-look                  # Look and feel configuration
    nwg-displays              # Configure Monitors 
    kitty-shell-integration   # Kitty terminal shell integration
    kitty-terminfo            # Terminfo for Kitty
    xdg-desktop-portal-gtk    # GTK implementation of xdg-desktop-portal
    xdg-user-dirs             # Manage user directories
    thunar                    # File Manager  
    thunar-media-tags-plugin  # Media tags plugin for Thunar
    thunar-shares-plugin      # Shares plugin for Thunar
    thunar-vcs-plugin         # VCS integration plugin for Thunar
    thunar-volman             # Volume management plugin for Thunar
    thunar-archive-plugin     # Archive plugin for Thunar
    update-grub               # Update GRUB bootloader
    bibata-cursor-theme       # Cursor theme
    gcolor3                   # Color picker
    gnome-calculator          # Math n stuff...
    tumbler                   # Thumbnailer
    hyprland-protocols        # Protocols for Hyprland
    power-profiles-daemon     # Power profile management
    file-roller               # Archive manager
    starship                  # Shell prompt
    unrar                     # RAR archive support
    unzip                     # ZIP archive support
    7zip                      # 7z archive support
    cava                      # Audio visualizer
    flatpak                   # Application sandbox and package manager
    gnome-disk-utility        # Disk Management
    libopenraw                # Lib for Tumbler
    libgsf                    # Lib for Tumbler
    poppler-glib              # Lib for Tumbler
    ffmpegthumbnailer         # Lib for Tumbler 
    freetype2                 # Lib for Tumbler
    libgepub                  # Lib for Tumbler
    gvfs                      # Needed for Thunar to see drives 
    yay                       # AUR Helper
    base-devel                # Build package
    clang                     # Build package
    matugen                   # Color Generation
    adw-gtk-theme             # Libadwaita theme
    loupe                     # Image viewer
)

OPTIONALPKG=(
    upscayl-desktop-git       # Upscaler for images on the fly
    video-downloader          # Download videos on your system, avoid sketchy websites! Yipee!
    mission-center            # Task Manager, Sleek
    protonplus                # Proton manager
    deadbeef                  # Modular Audio Player
)

# Descriptions for optional packages
declare -A OPTIONALPKG_DESC=(
    [upscayl-desktop-git]="Image upscaler (desktop GUI)"
    [video-downloader]="Download videos locally from various sources"
    [mission-center]="Sleek task manager / system monitor"
    [protonplus]="Proton/Wine manager for gaming"
    [deadbeef]="Modular audio player"
)

REPO_DIR=$(pwd)
CONFIG_DIR="$ACTUAL_USER_HOME/.config"

# Validate repo directory
if [ ! -d "$REPO_DIR/.config" ]; then
    echo "ERROR: Script must be run from the repository root directory."
    exit 1
fi

# --- Color Functions ---
disable_colors() {
    unset ALL_OFF BOLD BLUE GREEN RED YELLOW CYAN MAGENTA
}

enable_colors() {
    if tput setaf 0 &>/dev/null; then
        ALL_OFF="$(tput sgr0)"
        BOLD="$(tput bold)"
        RED="${BOLD}$(tput setaf 1)"
        GREEN="${BOLD}$(tput setaf 2)"
        YELLOW="${BOLD}$(tput setaf 3)"
        BLUE="${BOLD}$(tput setaf 4)"
        MAGENTA="${BOLD}$(tput setaf 5)"
        CYAN="${BOLD}$(tput setaf 6)"
    else
        ALL_OFF="\e[0m"
        BOLD="\e[1m"
        RED="${BOLD}\e[31m"
        GREEN="${BOLD}\e[32m"
        YELLOW="${BOLD}\e[33m"
        BLUE="${BOLD}\e[34m"
        MAGENTA="${BOLD}\e[35m"
        CYAN="${BOLD}\e[36m"
    fi
    readonly ALL_OFF BOLD BLUE GREEN RED YELLOW CYAN MAGENTA
}

if [[ -t 2 ]]; then
    enable_colors
else
    disable_colors
fi

# --- Chaotic-AUR Functions ---
print_header() {
    echo ""
    printf "${CYAN}${BOLD}   Chaotic-AUR Repository Setup${ALL_OFF}\n"
    printf "${YELLOW}${BOLD}   'The Fast Lane!'${ALL_OFF}\n"
    echo ""
}

msg() {
    printf "${GREEN}▶${ALL_OFF}${BOLD} ${1}${ALL_OFF}\n" >&2
}

info() {
    printf "${YELLOW}  •${ALL_OFF} ${1}${ALL_OFF}\n" >&2
}

error() {
    printf "${RED}  ✗${ALL_OFF} ${1}${ALL_OFF}\n" >&2
}

check_if_chaotic_repo_was_added() {
    cat /etc/pacman.conf | grep "chaotic-aur" > /dev/null
    echo $?
}

reorder_pacman_conf() {
    msg "Ensuring correct repository order in pacman.conf.."
    
    local pacman_conf="/etc/pacman.conf"
    local pacman_conf_backup="/etc/pacman.conf.bak.$(date +%s)"
    
    info "Backup current config"
    cp $pacman_conf $pacman_conf_backup
    
    # Remove any existing Chaotic-AUR entries
    sed -i '/^\[chaotic-aur\]/,/^$/d' $pacman_conf
    
    # Add Chaotic-AUR at the end
    echo "" >> $pacman_conf
    echo "[chaotic-aur]" >> $pacman_conf
    echo "Include = /etc/pacman.d/chaotic-mirrorlist" >> $pacman_conf
    
    info "Chaotic-AUR positioned at the end of pacman.conf"
    msg "Done configuring repository order"
}

install_chaotic_aur() {
    msg "Installing Chaotic-AUR repository.."
    printf "${CYAN}${BOLD}  🔑 Adding Chaotic-AUR GPG key...${ALL_OFF}\n"

    info "Adding Chaotic-AUR GPG key"
    pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    pacman-key --lsign-key 3056513887B78AEB

    printf "${CYAN}${BOLD}  📦 Installing Chaotic-AUR packages...${ALL_OFF}\n"
    info "Installing Chaotic-AUR keyring and mirrorlist"
    pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

    msg "Done installing Chaotic-AUR repository."
}

create_chaotic_mirrorlist() {
    msg "Creating Chaotic-AUR mirrorlist file.."
    
    if [[ ! -f /etc/pacman.d/chaotic-mirrorlist ]] || [[ ! -s /etc/pacman.d/chaotic-mirrorlist ]]; then
        info "Creating chaotic-mirrorlist"
        cat > /etc/pacman.d/chaotic-mirrorlist << 'EOF'
# Chaotic-AUR Mirrorlist
Server = https://cdn-mirror.chaotic.cx/chaotic-aur/$arch
Server = https://geo-mirror.chaotic.cx/chaotic-aur/$arch
EOF
    fi
    
    msg "Done creating mirrorlist file"
}

setup_chaotic_aur() {
    print_header
    msg "Setting up Chaotic-AUR repository.."
    
    local is_chaotic_added="$(check_if_chaotic_repo_was_added)"
    if [ $is_chaotic_added -eq 0 ]; then
        info "Chaotic-AUR repo is already installed!"
        info "Skipping installation steps"
    else
        install_chaotic_aur
        create_chaotic_mirrorlist
    fi
    
    reorder_pacman_conf
    
    echo ""
    printf "${GREEN}${BOLD}  ✓ SUCCESS${ALL_OFF}\n"
    printf "${GREEN}  Chaotic-AUR repository setup completed successfully!${ALL_OFF}\n"
    printf "${GREEN}  Repository is now positioned at the end of pacman.conf${ALL_OFF}\n"
    echo ""
    
    msg "Refreshing pacman mirrors..."
    pacman -Syy
    
    if [ $? -ne 0 ]; then
        echo "Warning: Failed to refresh pacman mirrors."
    fi
}

# --- Main Installation Functions ---

# Remove conflicting packages
remove_conflicting_packages() {
    echo "Removing conflicting packages..."
    pacman -Rns --noconfirm dolphin polkit-kde-agent vim
    
    if [ $? -eq 0 ]; then
        echo "Conflicting packages removed successfully."
    else
        echo "Warning: Some packages could not be removed (they may not be installed)."
    fi
}

# Function to handle optional package installation
install_optional_packages() {
    echo -e "\n--- Optional Packages Installation ---"
    echo "The following optional packages will be installed if you choose yes:"
    for pkg in "${OPTIONALPKG[@]}"; do
        desc="${OPTIONALPKG_DESC[$pkg]}"
        if [ -n "$desc" ]; then
            echo "  - $pkg: $desc"
        else
            echo "  - $pkg"
        fi
    done
    echo ""
    read -r -p "Do you want to install these optional packages? (y/N): " response
    
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Installing optional packages via pacman..."
        pacman -S --noconfirm "${OPTIONALPKG[@]}"
    else
        echo "Skipping optional package installation."
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
        
        # Fix ownership since we're running as root
        chown -R "$ACTUAL_USER:$ACTUAL_USER" "$TARGET_PATH"
    done
}

# Deploy files from repo/.local/share to ~/.local/share
deploy_local_share() {
    echo "Deploying local share files..."
    
    LOCAL_SOURCE_ROOT="$REPO_DIR/.local/share"
    LOCAL_TARGET_ROOT="$ACTUAL_USER_HOME/.local/share"

    if [ ! -d "$LOCAL_SOURCE_ROOT" ]; then
        echo "No .local/share directory found in repo, skipping..."
        return
    fi

    mkdir -p "$LOCAL_TARGET_ROOT"

    echo "Copying $LOCAL_SOURCE_ROOT -> $LOCAL_TARGET_ROOT"
    if [ "$(ls -A "$LOCAL_SOURCE_ROOT")" ]; then
        cp -a "$LOCAL_SOURCE_ROOT"/* "$LOCAL_TARGET_ROOT"/
        if [ $? -ne 0 ]; then
            echo "NON-FATAL ERROR: Failed to copy files from .local/share."
        fi
        
        # Fix ownership since we're running as root
        chown -R "$ACTUAL_USER:$ACTUAL_USER" "$LOCAL_TARGET_ROOT"
    else
        echo "Warning: .local/share directory is empty, skipping copy."
    fi
}

# Set executable permissions for scripts
set_permissions() {
    SCRIPTS_PATH="$ACTUAL_USER_HOME/.config/hypr/Scripts"
    
    if [ -d "$SCRIPTS_PATH" ]; then
        echo "Setting execution permissions for scripts..."
        find "$SCRIPTS_PATH" -type f -exec chmod +x {} \;
    else
        echo "Warning: Hyprland scripts directory '$SCRIPTS_PATH' not found."
    fi
}

# Install Tela Circle icon theme (final optional step)
install_tela_icons() {
    echo -e "\n--- Optional: Tela Circle Icon Theme ---"
    echo "The Tela Circle icon collection can be installed."
    echo "Repo: https://github.com/vinceliuice/Tela-circle-icon-theme"
    read -r -p "Do you want to install Tela Circle icons? (y/N): " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        WORKDIR="/tmp/Tela-circle-icon-theme-$$"
        mkdir -p "$WORKDIR"
        echo "Cloning repository to $WORKDIR ..."
        if ! git clone --depth=1 https://github.com/vinceliuice/Tela-circle-icon-theme.git "$WORKDIR/Tela-circle-icon-theme"; then
            echo "ERROR: Failed to clone Tela Circle icon theme repository."
            return 1
        fi
        cd "$WORKDIR/Tela-circle-icon-theme" || { echo "ERROR: Failed to enter repo directory."; return 1; }
        ICON_TARGET_DIR="$ACTUAL_USER_HOME/.local/share/icons"
        mkdir -p "$ICON_TARGET_DIR"
        echo "Running installer to '$ICON_TARGET_DIR' ..."
        # Run installer (script expects root for system-wide; we target user's icons dir)
        if ./install.sh -a -c -d "$ICON_TARGET_DIR"; then
            chown -R "$ACTUAL_USER:$ACTUAL_USER" "$ICON_TARGET_DIR"
            echo "Tela Circle icons installed to $ICON_TARGET_DIR"
        else
            echo "ERROR: Tela Circle icon installation failed."
            return 1
        fi
    else
        echo "Skipping Tela Circle icon installation."
    fi
}

# --- Main Installation Flow ---

echo "Starting Hyprland Dotfiles Installation..."

# 0. Setup Chaotic-AUR Repository
setup_chaotic_aur

# 1. Remove conflicting packages
remove_conflicting_packages

# 2. Install Core Packages
echo "Installing required core packages via pacman..."
echo "installing core packages in 3..."
echo "2..."
echo "1!"
pacman -S --noconfirm "${PACKAGES[@]}"

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install core packages. Aborting installation."
    exit 1
fi

# 3. Optional install packages
install_optional_packages

# 4. Deploy Configurations
deploy_configs
deploy_local_share

# 5. Set Script Permissions
set_permissions

# 6. Update user directories
echo "Updating user directories..."
sudo -u "$ACTUAL_USER" xdg-user-dirs-update

if [ $? -ne 0 ]; then
    echo "Warning: Failed to update user directories."
fi

# 7. Enable Bluetooth service
echo "Enabling Bluetooth service..."
systemctl enable bluetooth

if [ $? -ne 0 ]; then
    echo "Warning: Failed to enable Bluetooth service."
fi

echo "Installation complete!"
echo "--------------------------------------------------------"
echo "Next Steps:"
echo "1. Review customization points in README.md."
echo "2. Reboot your system."
echo "3. Select the Hyprland session at your login manager."
echo "--------------------------------------------------------"

# Install noctalia-shell-git via yay
echo "Installing noctalia-shell-git via yay..."
sudo -u "$ACTUAL_USER" yay -S --noconfirm noctalia-shell-git

if [ $? -ne 0 ]; then
    echo "Warning: Failed to install noctalia-shell-git."
fi

# Optional: Install Orchis GTK theme
echo -e "\n--- Optional: Orchis GTK Theme ---"
read -r -p "Do you want to install optional GTK themes? (y/n): " gtk_response
if [[ "$gtk_response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    WORKDIR="/tmp/Orchis-theme-$$"
    mkdir -p "$WORKDIR"
    echo "Cloning Orchis theme repository..."
    if ! git clone https://github.com/vinceliuice/Orchis-theme.git "$WORKDIR/Orchis-theme"; then
        echo "ERROR: Failed to clone Orchis theme repository."
    else
        cd "$WORKDIR/Orchis-theme" || { echo "ERROR: Failed to enter repo directory."; }
        echo "Installing Orchis theme..."
        if ./install.sh -c dark -t all; then
            echo "Orchis theme installed successfully."
        else
            echo "ERROR: Orchis theme installation failed."
        fi
    fi
else
    echo "Skipping GTK theme installation."
fi

# Final optional: install Tela Circle icons
install_tela_icons

# Custom theme installation
echo ""
echo "--- Custom Theme Installation ---"
echo "Would you like to install a custom theme?"
echo "Available themes:"
echo "  1. Catppuccin"
echo "  2. Gruvbox"
echo "  3. Nightfox Red"
echo "  4. Nord"
echo "  5. Tokyo"
echo "  6. No, skip theme installation"
echo ""

while true; do
    read -r -p "Enter your choice (1-6): " theme_choice
    case "$theme_choice" in
        1)
            echo "Installing Catppuccin theme..."
            THEME_SOURCE="$REPO_DIR/custom/Catppuccin/.config"
            if [ -d "$THEME_SOURCE" ]; then
                cp -rf "$THEME_SOURCE"/* "$CONFIG_DIR"/
                chown -R "$ACTUAL_USER:$ACTUAL_USER" "$CONFIG_DIR"
                echo "Catppuccin theme installed successfully!"
            else
                echo "ERROR: Catppuccin theme directory not found."
            fi
            break
            ;;
        2)
            echo "Installing Gruvbox theme..."
            THEME_SOURCE="$REPO_DIR/custom/Gruvbox/.config"
            if [ -d "$THEME_SOURCE" ]; then
                cp -rf "$THEME_SOURCE"/* "$CONFIG_DIR"/
                chown -R "$ACTUAL_USER:$ACTUAL_USER" "$CONFIG_DIR"
                echo "Gruvbox theme installed successfully!"
            else
                echo "ERROR: Gruvbox theme directory not found."
            fi
            break
            ;;
        3)
            echo "Installing Nightfox Red theme..."
            THEME_SOURCE="$REPO_DIR/custom/Nightfox Red/.config"
            if [ -d "$THEME_SOURCE" ]; then
                cp -rf "$THEME_SOURCE"/* "$CONFIG_DIR"/
                chown -R "$ACTUAL_USER:$ACTUAL_USER" "$CONFIG_DIR"
                echo "Nightfox Red theme installed successfully!"
            else
                echo "ERROR: Nightfox Red theme directory not found."
            fi
            break
            ;;
        4)
            echo "Installing Nord theme..."
            THEME_SOURCE="$REPO_DIR/custom/Nord/.config"
            if [ -d "$THEME_SOURCE" ]; then
                cp -rf "$THEME_SOURCE"/* "$CONFIG_DIR"/
                chown -R "$ACTUAL_USER:$ACTUAL_USER" "$CONFIG_DIR"
                echo "Nord theme installed successfully!"
            else
                echo "ERROR: Nord theme directory not found."
            fi
            break
            ;;
        5)
            echo "Installing Tokyo theme..."
            THEME_SOURCE="$REPO_DIR/custom/Tokyo/.config"
            if [ -d "$THEME_SOURCE" ]; then
                cp -rf "$THEME_SOURCE"/* "$CONFIG_DIR"/
                chown -R "$ACTUAL_USER:$ACTUAL_USER" "$CONFIG_DIR"
                echo "Tokyo theme installed successfully!"
            else
                echo "ERROR: Tokyo theme directory not found."
            fi
            break
            ;;
        6)
            echo "Skipping custom theme installation."
            break
            ;;
        *)
            echo "Invalid choice. Please enter a number between 1 and 6."
            ;;
    esac
done

# Reboot confirmation
echo ""
echo "Installation complete! Time to reboot."
while true; do
    read -r -p "Would you like to reboot now? (y/n): " reboot_choice
    case "$reboot_choice" in
        y|Y|yes|YES)
            echo "Rebooting now..."
            sudo reboot now
            break
            ;;
        n|N|no|NO)
            echo ""
            echo "Installation complete! Time to reboot."
            ;;
        *)
            echo "Please answer 'y' or 'n'."
            ;;
    esac
done
