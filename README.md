<p align="center">
  <img src="https://img.shields.io/github/last-commit/Echilonvibin/echilon-dotfiles" alt="Last Commit">
  <img src="https://img.shields.io/github/commit-activity/w/Echilonvibin/echilon-dotfiles" alt="Commit Activity">
  <img src="https://img.shields.io/github/license/Echilonvibin/echilon-dotfiles" alt="License">
</p>

# echilon-dotfiles

A curated collection of custom configuration files (dotfiles) for the **Hyprland** Wayland compositor, maintained by Echilon & Tonekneeo & Xnyte.

---

## ⚠️ Important Warnings & Disclaimer

### Fresh Install Requirement

**This configuration is tailored for a FRESH INSTALL of VANILLA ARCH LINUX with Hyprland.** We strongly advise against attempting this installation on derivative distributions (such as CachyOS, Manjaro, etc.) as package and configuration conflicts are highly likely. This includes packages you could install yourself, through Arch's repo, and a few AUR packages. This will install the chaotic AUR, the only AUR exclusive package that is installed, is the Noctalia bar itself. 

### Development Status

This configuration is in **active development** and is currently being "vibe coded." While all components are functional during testing, we advise using it **at your own risk**. More rigorous testing is scheduled.

### Credits

The primary application bar (`noctalia-shell-git`) is based on the exceptional work by **Noctalia**. All credit for the bar's design and functionality goes to them:

> [**noctalia-dev/noctalia-shell**](https://github.com/noctalia-dev/noctalia-shell)

---
![Red](Red.png)


![TokyoNight](TokyoNight.png)


## 📦 What's Included?

This repository provides comprehensive configurations for a complete, customized Hyprland desktop environment.

| Component | Description |
| :--- | :--- |
| **`hypr`** | Main Hyprland configuration, including keybinds, window rules, and workspace setup. **(Requires customization)** |
| **`kitty`** | Configuration for the primary GPU-accelerated terminal emulator. |
| **`fish`** | Configuration for the Fish shell, including custom functions and the Starship prompt. |
| **`Noctalia`** | The main bar, includes various theming settings, general use case settings. It's very much an all in one. |
| **`fastfetch`** | Configuration for displaying system information with custom images/ASCII art. |
| **`install.sh`** | An automated script for package installation and configuration deployment. |
| **`uninstall.sh`** | A script to revert changes and restore previous configurations (if a backup exists). |

---

## ⚙️ Customization Required

These dotfiles are provided strictly as a **template**. You **must** review and customize several files to align with your specific hardware, desired aesthetics, and system paths.

| File/Section | Customization Needed | Notes |
| :--- | :--- | :--- |
| **`hypr/hyprland.conf`** | Monitor setup (resolution, scaling, refresh rate). | The current default is `monitor=,preferred,auto,1`. You may use `nwg-displays` to help configure and export precise settings. |
| **`hypr/keybindings.conf`** | Set bindings here. Super+E is to open your file explorer. Super+D is the app launcher. |
| **Theming** | Color schemes, fonts, and global aesthetic settings. | The default theme is minimal. Customize these within Noctalia's settings, go to color scheme, and then templates, you can set kitty, GTK, or whatever else you would like to match your color scheme. |
| *NOTE* | | adw-gtk3-dark |  This will be needed to make changes to GTK. This comes preinstalled, you will have to set it in GTK the Settings. |
| **`fastfetch/config.jsonc`** | Theming/Images. | Update the configuration for your specific image or ASCII art display. |

---

## 🚀 Installation Guide

### Prerequisites

You must be running an **Arch-based Linux distribution** and have basic development tools installed (`git` is required for cloning).

### Step 1: Clone the Repository

Open your terminal and clone the repository using `git`:

```bash
git clone https://github.com/Echilonvibin/echilon-dotfiles.git
```

### Step 2: Change directory to the repo

Navigate into the cloned directory and execute the automated install.sh script:
cd ./echilon-dotfiles


### Step 3: Make the install script executable

```bash
chmod+x ./install.sh
```

### Step 4: Run the install script, YIPPE
```bash
sudo ./install.sh
```


Note: The install.sh script handles package installation via your package manager and deploys the dotfiles, creating a backup of any existing configuration files it overwrites.

# 🗑️ Uninstallation
If you need to revert the changes and restore your system to its previous state using the created backups, please follow these steps.

### Step 1: Run the Uninstallation Script
Navigate to the repository directory (if not already there) and execute the uninstall.sh script:

```bash
./uninstall.sh
```

### Step 2: Manually Remove Software (Optional)
The uninstallation script restores configurations but does not remove packages. If you wish to completely remove the installed software, you must run a separate command using your package manager (e.g., yay, pacman).

# Example command to remove core packages (adjust the list as needed)
```
yay -R nautilus noctalia-shell-git upscayl-bin video-downloader gnome-calculator loupe gcolor3 protonplus mission-center
```

