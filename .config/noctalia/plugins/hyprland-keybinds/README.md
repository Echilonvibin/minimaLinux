# Hyprland Keybinds Plugin

A Noctalia Shell plugin that allows you to view and edit your Hyprland keybinds configuration file directly from the shell.

## Features

- **Bar Widget**: Quick access button with keyboard icon in the bar
- **Panel**: Full-featured text editor for keybinds.conf
- **Settings**: Configure the path to your keybinds configuration file
- **Reload**: Refresh keybinds from file without reopening
- **Save**: Write changes back to the configuration file

## Usage

1. Click the keyboard icon in the bar to open the keybinds editor
2. Edit your keybinds in the text editor
3. Click "Save Changes" to write changes to the config file
4. Right-click the bar widget to reload keybinds from disk

## Configuration

Configure the plugin in Settings:
- **Config file path**: Path to your Hyprland keybinds file (default: `~/.config/hypr/keybinds.conf`)
- **Icon color**: Color of the bar widget icon

## IPC Commands

- `qs -c noctalia-shell ipc call plugin:hyprland-keybinds toggle` - Toggle the panel
- `qs -c noctalia-shell ipc call plugin:hyprland-keybinds reload` - Reload keybinds from file