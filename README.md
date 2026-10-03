<div align="center">

```text
   ⣴⣶⣆   ⢰⣶⣶⣶⣶⣶⣶⣦ ⢀⣴⣶⣶⣶⣶⣶⣶⡆⢰⣶⡆    ⣶⡆      ⢰⣶⡆     ⢰⣶⡆⢠⣶⣦⡀  ⢰⣶⡆⢰⣶⡆   ⢰⣶⡆ ⣶⣦   ⢰⣶⠆
  ⣸⣿⣿⣿⡄        ⣹⣿⡇⢸⣿⡏   ⠘⠛⠃⢸⣿⡇   ⢀⣿⡇      ⢸⣿⡇     ⢸⣿⡇⢸⣿⣿⣿⣆ ⢸⣿⡇⢸⣿⡇   ⢸⣿⡇ ⠸⣿⣆ ⣀⣿⡟
 ⢠⣿⡟⠈⣿⣷  ⢠⣿⣿⠿⠿⣿⣿⠟ ⢸⣿⡇      ⢸⣿⡿⠿⠿⠿⢿⣿⡇      ⢸⣿⡇     ⢸⣿⡇⢸⣿⡇⠹⣿⣷⣸⣿⡇⢸⣿⡇   ⢸⣿⡇  ⣿⣿⠿⢿⣿⡅
 ⣾⣿⠁ ⠸⣿⣇ ⢸⣿⡇  ☿⣿⣧ ⢸⣿⣧⣤⣤⣤⣤⣤⡄⢸⣿⡇    ⣿⡇      ⢸⣿⣧⣤⣤⣤⣤⡄⢸⣿⡇⢸⣿⡇ ⠈⢻⣿⣿⡇⢸⣿⣧⣤⣤⣤⣼⣿⡇ ⣸⣿⠃  ⢿⣷
⠘⠛⠃   ⠙⠛⠂⠘⠛⠃   ⠙⠛⠂ ⠙⠛⠛⠛⠛⠛⠛⠃⠘⠛⠃    ⠛⠃       ⠙⠛⠛⠛⠛⠛⠃⠘⠛⠃⠘⠛⠃   ⠙⠛⠁ ⠙⠛⠛⠛⠛⠛⠋ ⠐⠛⠋   ⠘⠛⠃
```

# Tegmentum OS

**A Minimal, High-Performance Arch Linux & Hyprland Environment**  
*Designed and crafted by [Vivekananda](https://github.com/vivekananda-2201)*

[![Arch Linux](https://img.shields.io/badge/Base-Arch%20Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org/)
[![Hyprland](https://img.shields.io/badge/Compositor-Hyprland%20(Lua)-00A3E0?style=for-the-badge&logo=wayland&logoColor=white)](https://hyprland.org/)
[![Quickshell](https://img.shields.io/badge/Interface-Quickshell-7aa2f7?style=for-the-badge)](https://quickshell.outfoxxed.me/)
[![Neovim](https://img.shields.io/badge/IDE-LazyVim%20%7C%20Oxocarbon-57A143?style=for-the-badge&logo=neovim&logoColor=white)](https://neovim.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

</div>

---

## Overview

**Tegmentum OS** is an engineered, keyboard-centric computing environment built on Arch Linux and the Hyprland Wayland compositor. Focused on operational speed, visual restraint, and hardware reliability, it provides an uncompromising workstation experience with unified design language, hardware-level power optimizations, and native interface widgets.

---

## Architecture & System Features

### Compositor & Display Management
- **Lua Configuration Engine**: Native configuration powered by Hyprland's Lua backend for modular, performant compositor control.
- **Physics-Calibrated Motion**: Custom cubic-bezier transition curves (`md3_decel`, `easeOutExpo`, `popin 60%`) tuned for instantaneous feedback and fluid window movement.
- **Intelligent Clamshell Handler**: Custom lid state dispatcher (`lid-handler.sh`) powers off the internal laptop screen and locks via `hyprlock`, while preserving connected external monitors intact without triggering GPU driver freezes.
- **Dynamic Display Configuration**: Automatic resolution and high-refresh detection (144Hz) with unified fallback scaling across multi-monitor topologies.

### Interactive Interface Suite (Quickshell)
- **Keybindings Visualizer (<kbd>Super</kbd> + <kbd>K</kbd>)**: Interactive modal cheatsheet with real-time fuzzy search. Selecting an entry isolates the binding in-place for 1 second before automatically fading away.
- **Precision Brightness HUD**: Custom animated on-screen display featuring 1% granular increments at low light levels (supporting true 0% for privacy) and 5% steps in normal ranges.
- **Control Center (<kbd>Super</kbd> + <kbd>I</kbd>)**: Fast toggles for network connections, Bluetooth devices, audio sinks, and display properties.
- **Wallpaper Orchestrator (<kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>W</kbd>)**: Powered by `hyprquickpaper`, featuring live thumbnail generation and real-time palette extraction.

### Status Bar & Launchers
- **Waybar**: Minimalist panel featuring optically balanced audio and battery metrics, live MPRIS media marquee, and system indicators.
- **Application Search (<kbd>Super</kbd> + <kbd>Space</kbd>)**: Fast fuzzy launcher powered by Rofi.
- **Power Menu (<kbd>Super</kbd> + <kbd>`</kbd>)**: Top-right session manager for instant Lock, Suspend, Hibernate, Reboot, and Shutdown.
- **Clipboard Management (<kbd>Super</kbd> + <kbd>V</kbd>)**: Cliphist clipboard cache integrated directly into Rofi with image and text previews.

### Development Environment & Terminal
- **Terminals**: Kitty and Alacritty configured with dynamic Matugen color syncing.
- **Floating Scratchpad Terminal (<kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>Return</kbd>)**: Dedicated terminal overlay for rapid terminal workflows.
- **Shell**: Zsh augmented with Starship prompt, syntax highlighting, autosuggestions, and prefix-matched history navigation.
- **Neovim / LazyVim**: Tailored LazyVim setup styled with the Oxocarbon dark theme, external buffer change detection, and high-speed fuzzy search (`ripgrep` / `fd`).
- **OLED GTK Theme**: Deep pitch-black `#000000` minimal dark theme across all GTK 3 and GTK 4 applications.

---

## Primary Keybindings

| Shortcut | Function |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>Return</kbd> | Launch Primary Terminal (Kitty) |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>Return</kbd> | Toggle Floating Terminal |
| <kbd>Super</kbd> + <kbd>Space</kbd> | Application Launcher (Rofi) |
| <kbd>Super</kbd> + <kbd>K</kbd> | Keybindings Visualizer & Search |
| <kbd>Super</kbd> + <kbd>Esc</kbd> | Power Menu (Top-Right) |
| <kbd>Super</kbd> + <kbd>W</kbd> | Close Active Window |
| <kbd>Super</kbd> + <kbd>B</kbd> | Hide / Restore Floating Windows |
| <kbd>Super</kbd> + <kbd>E</kbd> | File Manager (Nautilus) |
| <kbd>Super</kbd> + <kbd>F</kbd> | Toggle Fullscreen (Entire Screen) |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>F</kbd> | Toggle Full Window (Maximize / Tiled Fullscreen) |
| <kbd>Super</kbd> + <kbd>J</kbd> | Toggle Window Split (Vertical / Horizontal) |
| <kbd>Super</kbd> + <kbd>L</kbd> | **Toggle Workspace Layout (Dwindle / Scrolling)** |
| <kbd>Super</kbd> + <kbd>←/→/↑/↓</kbd> | Navigate / Focus Windows |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>←/→/↑/↓</kbd> | Move Active Window in Direction |
| <kbd>Super</kbd> + <kbd>+</kbd> / <kbd>-</kbd> | Resize Window Width (50px) |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>+</kbd> / <kbd>-</kbd> | Resize Window Height (50px) |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>+</kbd> / <kbd>-</kbd> | Precise Resize Width (10px) |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>Alt</kbd> + <kbd>+</kbd> / <kbd>-</kbd> | Precise Resize Height (10px) |
| <kbd>Alt</kbd> + <kbd>Tab</kbd> | Cycle Windows & Raise to Top |
| <kbd>Super</kbd> + <kbd>Tab</kbd> | Lock Session (Hyprlock) |
| <kbd>Super</kbd> + <kbd>I</kbd> | Open System Settings |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>W</kbd> | Open Wallpaper Selector |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>Space</kbd> | Toggle Waybar Visibility |
| <kbd>Super</kbd> + <kbd>V</kbd> | Clipboard History |
| <kbd>Print</kbd> | Fullscreen Screenshot |
| <kbd>Shift</kbd> + <kbd>Print</kbd> | Region Screenshot |
| <kbd>Brightness Keys</kbd> | Granular Brightness + OSD |
| <kbd>Volume Keys</kbd> | Audio Control + OSD |

---

## Installation

### Requirements
- Arch Linux or an Arch-based distribution (e.g., EndeavourOS, CachyOS).
- Active network connection and `git`.

### Quick Setup

```bash
git clone https://github.com/vivekananda-2201/Tegmentum-OS.git
cd Tegmentum-OS
chmod +x install.sh
./install.sh
```

### What the Installer Automates:
1. Detects package manager (`pacman`) and bootstraps AUR helper (`yay`) if needed.
2. Resolves and installs all required system, audio, UI, and font packages.
3. Automatically backs up existing configuration files to `~/.config-backups/`.
4. Deploys `.config` directories, shell scripts, and `.zshrc`.
5. Sets up PipeWire audio services (`pipewire`, `pipewire-pulse`, `wireplumber`).
6. Configures systemd logind (`HandleLidSwitch=ignore`) so Hyprland handles lid closing seamlessly.
7. Compiles initial theme palettes via Matugen and sets execution permissions.

---

## License

This project is licensed under the [MIT License](LICENSE).  
Authored and maintained by **Vivekananda** ([@vivekananda-2201](https://github.com/vivekananda-2201)).
