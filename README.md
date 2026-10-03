<div align="center">

```text
   ⣴⣶⣆   ⢰⣶⣶⣶⣶⣶⣶⣦ ⢀⣴⣶⣶⣶⣶⣶⣶⡆⢰⣶⡆    ⣶⡆      ⢰⣶⡆     ⢰⣶⡆⢠⣶⣦⡀  ⢰⣶⡆⢰⣶⡆   ⢰⣶⡆ ⣶⣦   ⢰⣶⠆
  ⣸⣿⣿⣿⡄        ⣹⣿⡇⢸⣿⡏   ⠘⠛⠃⢸⣿⡇   ⢀⣿⡇      ⢸⣿⡇     ⢸⣿⡇⢸⣿⣿⣿⣆ ⢸⣿⡇⢸⣿⡇   ⢸⣿⡇ ⠸⣿⣆ ⣀⣿⡟
 ⢠⣿⡟⠈⣿⣷  ⢠⣿⣿⠿⠿⣿⣿⠟ ⢸⣿⡇      ⢸⣿⡿⠿⠿⠿⢿⣿⡇      ⢸⣿⡇     ⢸⣿⡇⢸⣿⡇⠹⣿⣷⣸⣿⡇⢸⣿⡇   ⢸⣿⡇  ⣿⣿⠿⢿⣿⡅
 ⣾⣿⠁ ⠸⣿⣇ ⢸⣿⡇  ☿⣿⣧ ⢸⣿⣧⣤⣤⣤⣤⣤⡄⢸⣿⡇    ⣿⡇      ⢸⣿⣧⣤⣤⣤⣤⡄⢸⣿⡇⢸⣿⡇ ⠈⢻⣿⣿⡇⢸⣿⣧⣤⣤⣤⣼⣿⡇ ⣸⣿⠃  ⢿⣷
⠘⠛⠃   ⠙⠛⠂⠘⠛⠃   ⠙⠛⠂ ⠙⠛⠛⠛⠛⠛⠛⠃⠘⠛⠃    ⠛⠃       ⠙⠛⠛⠛⠛⠛⠃⠘⠛⠃⠘⠛⠃   ⠙⠛⠁ ⠙⠛⠛⠛⠛⠛⠋ ⠐⠛⠋   ⠘⠛⠃
```

# Tegmentum OS

**A performance-driven, keyboard-centric Arch Linux & Hyprland environment.**  
*Crafted with precision by [Vivekananda](https://github.com/vivekananda-2201).*

[![Arch Linux](https://img.shields.io/badge/Base-Arch%20Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org/)
[![Hyprland](https://img.shields.io/badge/Compositor-Hyprland%20(Lua)-00A3E0?style=for-the-badge&logo=wayland&logoColor=white)](https://hyprland.org/)
[![Quickshell](https://img.shields.io/badge/Widgets-Quickshell-7aa2f7?style=for-the-badge)](https://quickshell.outfoxxed.me/)
[![Neovim](https://img.shields.io/badge/Editor-LazyVim%20%7C%20Oxocarbon-57A143?style=for-the-badge&logo=neovim&logoColor=white)](https://neovim.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

</div>

---

> [!NOTE]
> **Vision:** Tegmentum OS began as a meticulously curated personal desktop environment on top of Arch Linux and Hyprland, tuned for high efficiency, seamless hybrid GPU management, and unified aesthetics. It is actively evolving into a fully standalone, out-of-the-box operating system distribution.

---

## Highlights & Features

### 1. Compositor & Display Management (Hyprland Lua)
- **Lua Configuration Backend**: Configured natively via Hyprland's modern Lua engine (`hyprland.lua`, `keybinds.lua`, `look.lua`, `monitors.lua`, `rules.lua`).
- **Dynamic Clamshell & Lid Switch**: Custom hardware dispatcher (`lid-handler.sh`) turns off only the internal laptop screen and locks the session via `hyprlock`. External monitors remain 100% active and intact without freezing hybrid GPUs (Intel/NVIDIA). Opening the lid immediately turns on the screen with `hyprlock` ready.
- **Adaptive Monitor Scaling**: Automatic HiDPI detection with high-refresh rate support (144Hz) and transparent fallback configuration for external displays.
- **Fluid Animation Curves**: Custom cubic-bezier animations (`md3_decel`, `easeOutExpo`, `popin 60%`) engineered for zero input delay and crisp window transitions.

### 2. Native Interactive Widgets (Quickshell)
- **Keybindings Visualizer (`Super + K`)**: Keyboard-driven cheatsheet window with instant fuzzy filtering. Pressing `Enter` isolates the selected row on screen for 1 second, then smoothly dissolves away.
- **Precision Brightness OSD**: Custom animated brightness indicator supporting fine 1% adjustments in low light (including 0% for privacy) and 5% steps in standard ranges.
- **Wallpaper Switcher (`Super + Shift + W`)**: Built on `hyprquickpaper` with instant wallpaper swapping, thumbnail caching, and automated palette extraction.
- **Settings Center (`Super + I`)**: Centralized toggle panel for Network, Bluetooth, Audio Sinks, per-app volume, and display configuration.

### 3. Top Status Bar (Waybar)
- **Optically Balanced Indicators**: Volume and Battery modules configured with custom font side-bearing compensation for uniform visual gaps.
- **Music Marquee & Controls**: Live MPRIS player title scrolling with play/pause and track skipping controls.
- **Power Menu Button**: Quick-launch trigger for the top-right Rofi power menu.

### 4. Application Launchers & Menus (Rofi)
- **Application Drawer (`Super + Space`)**: Fast fuzzy searching through all desktop apps.
- **Top-Right Power Menu (`Super + ` `)**: Sleek, high-contrast session manager positioned at the top right (Lock, Suspend, Hibernate, Logout, Reboot, Shutdown).
- **Clipboard History (`Super + V`)**: Cliphist manager integrated directly into Rofi with image and text preview.

### 5. Terminals & Shells
- **Kitty & Alacritty**: Pre-configured dual terminals with dynamic Matugen color generation and customized padding.
- **Floating Terminal (`Super + Ctrl + Enter`)**: Dedicated instant terminal overlay for quick tasks.
- **Zsh & Starship**: Ultra-responsive shell with syntax highlighting, autosuggestions, and Up/Down history prefix search.

### 6. Developer Environment (Neovim / LazyVim)
- Full LazyVim distribution customized with the high-contrast **Oxocarbon** colorscheme.
- Automatic disk reload notifications when buffers change externally.
- Fast fuzzy navigation powered by `ripgrep` and `fd`.

### 7. Pitch Black GTK 3 & GTK 4 Theme
- Handcrafted OLED minimal stylesheet (`gtk.css`) providing true `#000000` dark backgrounds across native GTK apps and file dialogs.

---

## Keybindings Cheatsheet

| Keybinding | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>Return</kbd> | Open Primary Terminal (Kitty) |
| <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>Return</kbd> | Open Floating Terminal |
| <kbd>Super</kbd> + <kbd>Space</kbd> | Application Launcher (Rofi) |
| <kbd>Super</kbd> + <kbd>K</kbd> | **Keybindings Visualizer (Search & Auto-dismiss)** |
| <kbd>Super</kbd> + <kbd>`</kbd> | **Power Menu (Top-Right Rofi)** |
| <kbd>Super</kbd> + <kbd>W</kbd> | Close Focused Window |
| <kbd>Super</kbd> + <kbd>B</kbd> | Hide / Unhide Floating Windows |
| <kbd>Super</kbd> + <kbd>E</kbd> | File Manager (Nautilus) |
| <kbd>Super</kbd> + <kbd>F</kbd> | Toggle Fullscreen |
| <kbd>Super</kbd> + <kbd>Tab</kbd> | Lock Screen (Hyprlock) |
| <kbd>Super</kbd> + <kbd>I</kbd> | Toggle Settings Panel |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>W</kbd> | Wallpaper Picker (`hyprquickpaper`) |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>Space</kbd> | Toggle Waybar Visibility |
| <kbd>Super</kbd> + <kbd>V</kbd> | Clipboard History |
| <kbd>Print</kbd> | Fullscreen Screenshot |
| <kbd>Super</kbd> + <kbd>Print</kbd> | Interactive Area Screenshot |
| <kbd>Brightness Keys</kbd> | Brightness Control (0–100%) + Quickshell OSD |
| <kbd>Volume Keys</kbd> | Audio Control + Quickshell OSD |

*Press <kbd>Super</kbd> + <kbd>K</kbd> at any time to open the live interactive keybinding cheatsheet.*

---

## Installation

### Prerequisites
- An **Arch Linux** installation (or Arch derivatives: EndeavourOS, CachyOS, Manjaro).
- Working internet connection and `git`.

### Quick Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/vivekananda-2201/Tegmentum-OS.git
   cd Tegmentum-OS
   ```

2. **Run the automated installer:**
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

### What `install.sh` Does:
- Verifies Arch compatibility and detects or bootstraps `yay` / `paru`.
- Automatically splits and installs all official and AUR packages from [`packages.txt`](packages.txt).
- Sets up PipeWire audio services (`pipewire`, `wireplumber`).
- Configures systemd logind (`/etc/systemd/logind.conf.d/hyprland-lid.conf`) to delegate laptop lid actions cleanly to Hyprland without sleeping.
- Backs up existing `~/.config` files to `~/.config-backups/<timestamp>/`.
- Installs all `.config` files and `.zshrc`.
- Automatically sets executable permissions on all shell scripts.
- Generates initial themes and palettes dynamically with `theme.py`.

3. **Log out and select Hyprland** at your display manager (or launch with `Hyprland`).

---

## Long-Term OS Roadmap

- [x] **Phase 1: Foundation (Current)**
  - Comprehensive Hyprland + Quickshell + Waybar desktop environment.
  - Hybrid laptop lid management and clamshell support.
  - Interactive cheatsheet visualizer and precision OSD widgets.
  - Automated installation and package management pipeline.
- [ ] **Phase 2: Custom Tooling & System Packaging**
  - Standalone `tegmentum-cli` for system updates and configuration switches.
  - Dedicated package repository hosting custom compiled binaries.
  - Integrated backup/restore snapshots with Btrfs/Snapper.
- [ ] **Phase 3: Turnkey Distribution ISO**
  - Custom Archiso profile with Calamares / archinstall integration.
  - Bootable live media with pre-installed Tegmentum environment.

---

## Credits & License

- Designed and developed by **Vivekananda** ([@vivekananda-2201](https://github.com/vivekananda-2201)).
- Core components built on top of [Hyprland](https://github.com/hyprwm/Hyprland), [Quickshell](https://github.com/outfoxxed/quickshell), and [Arch Linux](https://archlinux.org/).
- Licensed under the [MIT License](LICENSE).
