# Dotfiles Modifications & Customization Log

This document lists all system changes, bug fixes, performance improvements, and personal configurations applied to transition from the base **43PR dotfiles** into your own personalized setup.

---

## 1. Nuked Invisible Top-Edge Mouse Hover Triggers
- **Problem**: Brushing the mouse cursor against the top of the screen (over Waybar) accidentally launched `hyprlock`, settings, Rofi, wallpaper chooser, or the power menu.
- **Root Cause**: An invisible 10px overlay panel ([`SettingsCornerTrigger.qml`](file:///home/vicky/.config/quickshell/SettingsCornerTrigger.qml)) in Quickshell captured mouse hover events across 5 horizontal zones.
- **Changes**:
  - Removed `SettingsCornerTrigger {}` from [`~/.config/quickshell/shell.qml`](file:///home/vicky/.config/quickshell/shell.qml) and [`~/dotfiles/.config/quickshell/shell.qml`](file:///home/vicky/dotfiles/.config/quickshell/shell.qml).
  - Deleted `SettingsCornerTrigger.qml` from local configs and staged its deletion in git.
  - Restarted Quickshell cleanly with zero mouse-trigger interference. All shortcuts (<kbd>Super</kbd>+<kbd>I</kbd>, <kbd>Super</kbd>+<kbd>W</kbd>, etc.) remain intact.

---

## 2. Neovim, LazyVim & Oxocarbon Theme
- **Problem**: Opening `nvim` resulted in a dark, empty screen and `module 'lazy' not found`.
- **Root Cause**: An interrupted initial clone left a corrupted, empty working directory in `~/.local/share/nvim/lazy/lazy.nvim`. Because the folder existed, Lazy skipped cloning and failed to start.
- **Changes**:
  - Nuked corrupted directory in `~/.local/share/nvim/lazy` and performed a clean clone of `lazy.nvim` (stable).
  - Successfully synced and downloaded all 32 core LazyVim plugins (dashboard, treesitter, lualine, bufferline, which-key, snacks).
  - Created [`~/.config/nvim/lua/plugins/colorscheme.lua`](file:///home/vicky/.config/nvim/lua/plugins/colorscheme.lua) configuring `nyoom-engineering/oxocarbon.nvim`.
  - Built and verified Oxocarbon as the active colorscheme.
  - Added full `~/.config/nvim` into [`~/dotfiles/.config/nvim`](file:///home/vicky/dotfiles/.config/nvim) so it installs automatically on fresh machines.

---

## 3. Mouse Cursor Size
- **Problem**: Cursor was set to an unusually tiny size (14px).
- **Changes**:
  - Increased `XCURSOR_SIZE` and added `HYPRCURSOR_SIZE` to **24** (standard size) in [`~/.config/hypr/hyprland.lua`](file:///home/vicky/.config/hypr/hyprland.lua) and [`~/dotfiles/.config/hypr/hyprland.lua`](file:///home/vicky/dotfiles/.config/hypr/hyprland.lua).
  - Updated GTK 3 & GTK 4 cursor size to 24 in `settings.ini`.
  - Applied cursor changes live via `hyprctl setcursor default 24`.

---

## 4. Wallpapers & Wallpaper Switcher (`hyprquickpaper`)
- **Downloaded Collections**:
  - Downloaded all full-resolution wallpapers from 43PR Wallhaven collections into [`~/Pictures/Wallpapers`](file:///home/vicky/Pictures/Wallpapers/):
    - Initial collection (`2097425`): 59 wallpapers.
    - Added collection (`1262809`): 102 wallpapers.
    - Added collection (`1401848`): 10 wallpapers.
    - Added collection (`1262811`): 174 wallpapers.
    - **Total Active Wallpapers**: 345 high-resolution wallpapers.
- **Fixed Thumbnail Caching**:
  - Fixed [`cache.sh`](file:///home/vicky/.config/quickshell/hyprquickpaper/cache.sh) by replacing the hard dependency on `jq` with Python JSON parsing and switching to modern ImageMagick `magick`.
  - Fixed a subshell pipeline bug so all background jobs complete. Generated all 345/345 thumbnails in `~/.cache/quickshell/thumbs/`.
  - Added fallback in [`shell.qml`](file:///home/vicky/.config/quickshell/hyprquickpaper/shell.qml) to display the original image if a thumbnail is missing.
- **Full Keyboard Navigation**:
  - Added full keyboard controls: <kbd>←</kbd> / <kbd>→</kbd> / <kbd>↑</kbd> / <kbd>↓</kbd> / <kbd>H</kbd> / <kbd>L</kbd>, <kbd>PageUp</kbd> / <kbd>PageDown</kbd>, <kbd>Home</kbd> / <kbd>End</kbd>, <kbd>Enter</kbd> / <kbd>Space</kbd> (apply), and <kbd>Esc</kbd> / <kbd>Q</kbd> (exit).
  - Reduced animation duration from 1000ms to 250ms for snappy responsiveness.
  - Eliminated mouse hover fighting: hovering only updates selection if the mouse physically moves across the screen.
- **Fixed First 5 Wallpapers Coordinate Bug**:
  - Fixed `contentX` formula: `contentX = i * step - sideMargin`. The first 5 wallpapers (0 to 4) can now be smoothly focused and centered.
- **Center on Current Wallpaper & Category**:
  - Automatically identifies which directory the currently active wallpaper belongs to (`LandScapes`, `Main`, `Sci-Fi_CyberPunk`, etc.), loads that folder, and centers the carousel on that exact wallpaper.
- **Dynamic Multi-Directory Support & Navigation**:
  - Dynamically discovers all subfolders inside `~/Pictures/Wallpapers/` via `FolderListModel` so new folders are detected automatically without configuration changes.
  - Added folder switching shortcuts:
    - <kbd>↓</kbd> / <kbd>J</kbd>: Switch to next folder.
    - <kbd>↑</kbd> / <kbd>K</kbd>: Switch to previous folder.
    - <kbd>←</kbd> / <kbd>→</kbd> / <kbd>H</kbd> / <kbd>L</kbd>: Browse wallpapers inside the current folder.
    - <kbd>Enter</kbd> / <kbd>Space</kbd>: Apply wallpaper.
  - **Ephemeral Bold Folder Title**: Removed static top buttons in favor of an elegant, bold folder name that appears prominently centered on top only when switching directories, remaining visible for 1.5 seconds before smoothly fading out.

---

## 5. Kitty Terminal Customizations
- **Cursor Shape**:
  - Set `cursor_shape block`.
  - Configured `shell_integration enabled no-cursor` so Zsh/bash prompt never overrides the block cursor back to a beam.
- **Padding**:
  - Added 4px left-edge padding: `window_padding_width 0 0 0 4`.
- **Live Reload**:
  - Applied via `SIGUSR1`. Updated both [`~/.config/kitty/kitty.conf`](file:///home/vicky/.config/kitty/kitty.conf) and [`~/dotfiles/.config/kitty/kitty.conf`](file:///home/vicky/dotfiles/.config/kitty/kitty.conf).

---

## 6. Shell Configuration Check
- Confirmed that your system is actively running **Zsh** (`/bin/zsh`) as the default login shell.
- Verified that [`~/.zshrc`](file:///home/vicky/.zshrc) includes Starship prompt, `zsh-autosuggestions`, `zsh-syntax-highlighting`, and `eza` aliases.

---

## 7. Default File Manager (Nautilus)
- **Default Application**:
  - Set `org.gnome.Nautilus.desktop` as default for `inode/directory` in [`~/.config/mimeapps.list`](file:///home/vicky/.config/mimeapps.list).
- **Hyprland Keybind**:
  - Updated `fileManager = "nautilus --new-window"` in [`~/.config/hypr/hyprland.lua`](file:///home/vicky/.config/hypr/hyprland.lua).
  - Using `--new-window` guarantees that pressing <kbd>Super</kbd>+<kbd>E</kbd> opens a window immediately on your active workspace instead of quietly focusing an existing window on another workspace.
- **Dotfiles & Packages**:
  - Replaced `thunar` with `nautilus` in [`~/dotfiles/packages.txt`](file:///home/vicky/dotfiles/packages.txt).
  - Provided command to remove Dolphin: `sudo pacman -Rns dolphin`.

---

## 8. GTK 3 / GTK 4 / Libadwaita & `nwg-look` Dark Theming
- **Problem**: Nautilus sidebar was blinding white with invisible text; `nwg-look` showed white boxes for buttons, text inputs, and the widget list.
- **Root Cause**:
  - System `color-scheme` was set to `'default'` (light mode) and `gtk-application-prefer-dark-theme` was `0`.
  - `gtk.css` had `* { color: @gtk_fg; }` which forced white text over light-colored widgets.
  - Buttons, entries, comboboxes, viewports, and scrolledwindows were unstyled.
  - `nwg-look` cached the old light theme in `~/.local/share/nwg-look/gsettings`.
- **Changes**:
  - Set `color-scheme: prefer-dark`, `gtk-theme: Adwaita-dark`, and `icon-theme: Papirus-Dark`.
  - Set `gtk-application-prefer-dark-theme=1` in both `gtk-3.0/settings.ini` and `gtk-4.0/settings.ini`.
  - Mapped all Libadwaita semantic colors (`@sidebar_bg_color`, `@window_bg_color`, `@card_bg_color`) in both `gtk-3.0/gtk.css` and `gtk-4.0/gtk.css`.
  - Added complete dark styles for `button`, `entry`, `combobox`, `spinbutton`, `scrolledwindow`, and `viewport`.
  - Synchronized [`~/.local/share/nwg-look/gsettings`](file:///home/vicky/.local/share/nwg-look/gsettings) and [`~/.config/xsettingsd/xsettingsd.conf`](file:///home/vicky/.config/xsettingsd/xsettingsd.conf).

---

## 9. Will `install.sh` from `~/dotfiles` Include These Changes?

**YES!** 

All changes have been synchronized directly into [`~/dotfiles`](file:///home/vicky/dotfiles/):
1. **Config Directory**: Every file in [`~/dotfiles/.config/`](file:///home/vicky/dotfiles/.config/) has been updated (Hyprland, Kitty, Quickshell, GTK 3 & 4, mimeapps, and Neovim).
2. **Neovim Added**: [`~/dotfiles/.config/nvim`](file:///home/vicky/dotfiles/.config/nvim) is now tracked in your repo with LazyVim and Oxocarbon.
3. **MIME Apps Added**: [`~/dotfiles/.config/mimeapps.list`](file:///home/vicky/dotfiles/.config/mimeapps.list) is tracked so Nautilus is always the default file manager.
4. **Packages List**: [`~/dotfiles/packages.txt`](file:///home/vicky/dotfiles/packages.txt) installs `nautilus` instead of `thunar`.

When you run `./install.sh`:
- It runs `cp -a "$REPO_DIR/.config/." "$CONFIG_DIR/"`, so **100% of your configurations and patches will be deployed**.
---

## 10. Pitch Black OLED Minimal Theme & Subtle Blue Hover Feedback (Nautilus & GTK)
- **Goal**: Pure pitch black (`#000000`) background, minimal premium aesthetic, native compact sidebar sizing, and transparent subtle blue gradient feedback syncing with the system palette.
- **Files Configured**:
  - [`~/.config/gtk-4.0/gtk.css`](file:///home/vicky/.config/gtk-4.0/gtk.css) & [`~/dotfiles/.config/gtk-4.0/gtk.css`](file:///home/vicky/dotfiles/.config/gtk-4.0/gtk.css)
  - [`~/.config/gtk-3.0/gtk.css`](file:///home/vicky/.config/gtk-3.0/gtk.css) & [`~/dotfiles/.config/gtk-3.0/gtk.css`](file:///home/vicky/dotfiles/.config/gtk-3.0/gtk.css)
- **Visual Enhancements Implemented**:
  1. **Pitch Black Surfaces**: Window background, headerbar, sidebar, and file view are true `#000000` (OLED black).
  2. **Native Left Panel Sizing**: Removed custom row padding/margins so sidebar buttons keep their natural, compact dimensions without height or width inflation.
  3. **Transparent Blue Gradient Hover**: Hovering over sidebar rows, files, buttons, or breadcrumbs uses a transparent background with a soft, very subtle horizontal blue gradient (`linear-gradient(to right, rgba(152, 204, 249, 0.14), rgba(152, 204, 249, 0.02))`) and sleek border outline.
  4. **Active Section & Selection Feedback**: Active sidebar items and selected files render with a luminous translucent blue gradient (`rgba(152, 204, 249, 0.22)`), icy blue text (`#98ccf9`), and crisp border (`rgba(152, 204, 249, 0.40)`), perfectly matching the terminal and Matugen theme.
  5. **Popovers & Context Menus**:
     - Stripped the outer subsurface container (`popover`, `popover.menu`) of background and borders, completely removing the bloated outer double-frame.
     - The inner menu bubble (`popover > contents`) now renders as a sleek, pitch-black (`#000000`) floating card with a razor-thin 1px border (`#1c1c1c`) and subtle shadow.
     - Right-click menu items (`modelbutton`) are styled identically to the sidebar rows with matching compact height (`min-height: 24px; padding: 3px 8px;`) and the same subtle transparent blue hover/active gradient.
---

## 11. Complete Default CAVA Configuration
- **Goal**: Provide the complete, official default CAVA configuration (with all parameters, sections, and documentation intact) that naturally syncs with terminal colors.
- **Files Configured**:
  - [`~/.config/cava/config`](file:///home/vicky/.config/cava/config) & [`~/dotfiles/.config/cava/config`](file:///home/vicky/dotfiles/.config/cava/config)
- **Changes**:
  - Generated the complete 343-line official default configuration directly from the CAVA binary.
  - Includes all 6 full sections: `[general]`, `[input]`, `[output]`, `[color]`, `[smoothing]`, and `[eq]`.
  - In `[color]`, defaults to `background = default`, `foreground = default`, and `gradient = 0`, ensuring CAVA dynamically inherits your terminal's colors, background, and palette.

---

## 12. Browser & Application File Chooser Dialog Theme Sync
- **Problem**: Whenever selecting or saving files in browsers or desktop apps, the file chooser dialog showed broken, blinding white boxes for the "Cancel" button, pathbar breadcrumbs, filename input, file list column headers, and filter dropdowns.
- **Root Cause**:
  - File picker dialogs are provided by `xdg-desktop-portal-gtk`, which is a GTK 3 daemon.
  - GTK 3 settings were set to `gtk-theme-name=Adwaita` (light mode base), and the portal daemon had been running continuously in the background since boot with the cached light theme.
  - File chooser specific widgets (`placessidebar`, `treeview header button`, `widget.path-bar button`, `combobox`, and `dialog-action-area button`) lacked custom dark rules.
- **Changes**:
  - Configured `gtk-theme-name=Adwaita-dark` in [`~/.config/gtk-3.0/settings.ini`](file:///home/vicky/.config/gtk-3.0/settings.ini), [`~/.config/xsettingsd/xsettingsd.conf`](file:///home/vicky/.config/xsettingsd/xsettingsd.conf), and `gsettings`.
  - Styled all file chooser components in both GTK 3 and GTK 4:
    - **Headerbar Titles & Text**: Crisp, legible light text (`#eaecef` with bold weight for titles, `#8e95a0` for subtitles) on pitch-black `#000000` headerbars.
    - **Filename & Search Inputs**: Input boxes (`entry`, `headerbar entry`, `filechooser entry`) are OLED pitch black (`#050505`) with readable `#eaecef` text and subtle `#98ccf9` active focus border.
    - **Crisp Window Framing**: Preserved clean 1px outline and structural separation matching the active window theme.
    - **Places Sidebar & Path Bar**: Compact geometry with subtle translucent blue hover and active states.
    - **Column Headers & Action Buttons**: Dark `#050505` column headers (*Name*, *Size*, *Type*, *Modified*) and sleek dark action buttons (*Cancel*, *Open*, *Save*).
  - **Hyprland Dialog Sizing & Centering**:
    - Added dedicated window rules in [`~/.config/hypr/rules.lua`](file:///home/vicky/.config/hypr/rules.lua) matching `xdg-desktop-portal-gtk` dialogs and open/save window titles.
    - All file selection dialogs now automatically float, open perfectly centered, and resize to a clean rectangular proportion of **950 x 750**.
  - Restarted `xdg-desktop-portal-gtk.service` and `xdg-desktop-portal.service`, and reloaded Hyprland rules live via `hyprctl reload`.

---

## 13. Floating Terminal Window Rule & Maximize Suppression
- **Problem**: Opening the custom floating terminal (<kbd>Super</kbd>+<kbd>Ctrl</kbd>+<kbd>Enter</kbd>) initially opened as a floating window but suddenly expanded / maximized to full screen.
- **Root Cause**:
  - The floating terminal launches Kitty with `--class floating-terminal`.
  - On startup under Wayland, Kitty emits an `xdg_toplevel::set_maximized` configure request.
  - Hyprland had `suppress_event = "maximize"` configured only for `class = "kitty"`. Because the floating terminal had `class = "floating-terminal"`, the maximize request was not ignored, causing Hyprland to instantly expand the window to full screen.
- **Changes**:
  - In [`~/.config/hypr/rules.lua`](file:///home/vicky/.config/hypr/rules.lua) and [`~/dotfiles/.config/hypr/rules.lua`](file:///home/vicky/dotfiles/.config/hypr/rules.lua):
    - Added `suppress_event = "maximize"` directly into the `floating-terminal` window rule.
    - Updated the general Kitty maximize suppression rule to match `class = "^(kitty|floating-terminal)$"`.
  - Reloaded Hyprland configuration live via `hyprctl reload`. The floating terminal now stays reliably floating, centered at 850 x 650 without expanding.

---

## 14. Screenshot Keybinds Migrated to PrintScreen
- **Problem**: Screenshots were originally bound to <kbd>Delete</kbd> (fullscreen) and <kbd>Shift</kbd>+<kbd>Delete</kbd> (area select), conflicting with standard text editing and terminal navigation.
- **Changes**:
  - In [`~/.config/hypr/keybinds.lua`](file:///home/vicky/.config/hypr/keybinds.lua) and [`~/dotfiles/.config/hypr/keybinds.lua`](file:///home/vicky/dotfiles/.config/hypr/keybinds.lua):
    - Replaced `Delete` with `Print` (<kbd>PrintScreen</kbd>) for fullscreen capture.
    - Replaced `SHIFT + Delete` with `SHIFT + Print` (<kbd>Shift</kbd>+<kbd>PrintScreen</kbd>) for area selection capture via `slurp`.
  - Reloaded Hyprland configuration live via `hyprctl reload`. Freeing <kbd>Delete</kbd> for regular usage.

---

## 15. Alt-Tab Window Cycling
- **Goal**: Provide classic window cycling shortcuts to quickly switch between open windows.
- **Changes**:
  - In [`~/.config/hypr/keybinds.lua`](file:///home/vicky/.config/hypr/keybinds.lua) and [`~/dotfiles/.config/hypr/keybinds.lua`](file:///home/vicky/dotfiles/.config/hypr/keybinds.lua):
    - Added <kbd>Alt</kbd> + <kbd>Tab</kbd>: Cycle forward through all open windows and bring the active window to the top.
    - Added <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>Tab</kbd>: Cycle backward through all open windows.
  - Reloaded Hyprland configuration live via `hyprctl reload`.

---

## 16. Terminal Command History Prefix Search (Up / Down Arrow)
- **Goal**: When typing a command prefix (e.g. `git`, `hyprctl`, `pacman`) and pressing the Up Arrow (<kbd>↑</kbd>), cycle backward through history for previous commands starting with that exact typed string. Pressing Down Arrow (<kbd>↓</kbd>) cycles forward through the matching commands or returns to the current buffer.
- **Implementation**:
  - Configured Zsh's standard `up-line-or-beginning-search` and `down-line-or-beginning-search` widgets.
  - Registered prior to plugin initialization to ensure `zsh-syntax-highlighting` and `zsh-autosuggestions` hook into the widgets seamlessly.
  - Bound both ANSI escape sequences (`^[[A`, `^[[B`), application cursor mode sequences (`^[OA`, `^[OB`), terminfo keys (`$terminfo[kcuu1]`, `$terminfo[kcud1]`), and `vicmd` mode.
  - If the prompt line is empty, Up / Down continue to behave as normal history previous / next navigation.
- **Files Modified**:
  - [`~/.zshrc`](file:///home/vicky/.zshrc)
  - [`~/dotfiles/.config/.zshrc`](file:///home/vicky/dotfiles/.config/.zshrc)

---

## 17. Laptop Brightness Hotkeys & Top-Center OSD Flyout
- **Goal**: Configure laptop brightness hotkeys (`XF86MonBrightnessUp` / `XF86MonBrightnessDown`) and create a sleek top-center brightness OSD matching the exact visual aesthetic, geometry, colors, and animations of the volume control capsule flyout.
- **Root Cause**:
  - The laptop brightness keys were not mapped in Hyprland's [`keybinds.lua`](file:///home/vicky/.config/hypr/keybinds.lua).
  - Quickshell only had an OSD component for Volume/Media and Screenshots, lacking a dedicated Brightness OSD component.
- **Implementation**:
  - **Quickshell Brightness OSD Component**: Created [`~/.config/quickshell/BrightnessOsd.qml`](file:///home/vicky/.config/quickshell/BrightnessOsd.qml) and mounted it in [`~/.config/quickshell/shell.qml`](file:///home/vicky/.config/quickshell/shell.qml):
    - **Aesthetic Match**: 320x28 pill capsule (`radius: 36`), top-centered at `anchors.topMargin: 30`, translucent dark backdrop (`Theme.alpha(Theme.bg, 0.5)`), matching 150ms opacity/scale pop-in and 1.2s auto-hide timer.
    - **Nerd Font Glyphs**: Dynamic brightness levels (`󰃞` low, `󰃟` medium, `󰃠` high) in `Symbols Nerd Font` 20px matching Volume icon styling.
    - **Smooth Progress Bar**: Animated track (`#555555`) with `Theme.text` fill matching Volume bar dimensions and easing.
    - **IPC Handler**: Exposes `target brightness` with `notify(pct)` for instantaneous updates without polling overhead.
  - **Brightness Helper Script**: Created [`~/.config/hypr/scripts/brightness.sh`](file:///home/vicky/.config/hypr/scripts/brightness.sh):
    - Uses `brightnessctl` allowing full dim down to `0%` for complete screen privacy when requested.
    - **Adaptive Step Sizing**:
      - **0% to 10%**: Fine-grained 1% adjustments (0% ↔ 1% ↔ ... ↔ 9% ↔ 10%) for high-precision control in dim environments or privacy.
      - **Above 10%**: Standard 5% steps (10% ↔ 15% ↔ 20% ↔ ... ↔ 100%).
    - Directly extracts the resulting percentage and notifies Quickshell via `qs ipc call brightness notify "$PCT"`.
  - **Hyprland Keybindings**: Added repeating and locked keybinds for `XF86MonBrightnessUp` and `XF86MonBrightnessDown` calling `brightness.sh`.
- **Files Modified / Created**:
  - [`~/.config/hypr/scripts/brightness.sh`](file:///home/vicky/.config/hypr/scripts/brightness.sh) & [`~/dotfiles/.config/hypr/scripts/brightness.sh`](file:///home/vicky/dotfiles/.config/hypr/scripts/brightness.sh)
  - [`~/.config/quickshell/BrightnessOsd.qml`](file:///home/vicky/.config/quickshell/BrightnessOsd.qml) & [`~/dotfiles/.config/quickshell/BrightnessOsd.qml`](file:///home/vicky/dotfiles/.config/quickshell/BrightnessOsd.qml)
  - [`~/.config/quickshell/shell.qml`](file:///home/vicky/.config/quickshell/shell.qml) & [`~/dotfiles/.config/quickshell/shell.qml`](file:///home/vicky/dotfiles/.config/quickshell/shell.qml)
  - [`~/.config/hypr/keybinds.lua`](file:///home/vicky/.config/hypr/keybinds.lua) & [`~/dotfiles/.config/hypr/keybinds.lua`](file:///home/vicky/dotfiles/.config/hypr/keybinds.lua)

---

## 18. Waybar Top Bar Battery Module
- **Goal**: Add a battery percentage indicator directly to the right side of the volume percentage in Waybar, matching its exact UI aesthetic, typography, spacing, and hover animations.
- **Implementation**:
  - **Module Placement**: Added `battery` right after `pulseaudio` in `modules-right` inside [`~/.config/waybar/config.jsonc`](file:///home/vicky/.config/waybar/config.jsonc).
  - **Configuration**:
    - Format: `"{icon} {volume}%"` for volume and `"{icon}{capacity}%"` / `"󰂄{capacity}%"` for battery (compensated for the battery glyph's built-in font side-bearing to achieve an identical perceived optical gap).
    - Icons: 11-step Nerd Font battery glyphs (`󰂎` to `󰁹`) mapped to capacity thresholds.
    - Warning (30%) & Critical (15%) states with `@wb_critical` alert color when low on battery.
    - Informative hover tooltip with estimated remaining time and wattage.
  - **Styling**:
    - Matched `13px` font size, `@wb_text` color, `0 10px` padding with `0 2px` margin in [`~/.config/waybar/style.css`](file:///home/vicky/.config/waybar/style.css).
    - Preserved `0.15s` font-size hover expansion to `15px` consistent with all other top-bar modules.
    - Set `padding-right: 0; margin-right: 0` for seamless, symmetric spacing between volume, battery, and network.
- **Files Modified**:
  - [`~/.config/waybar/config.jsonc`](file:///home/vicky/.config/waybar/config.jsonc) & [`~/dotfiles/.config/waybar/config.jsonc`](file:///home/vicky/dotfiles/.config/waybar/config.jsonc)
  - [`~/.config/waybar/style.css`](file:///home/vicky/.config/waybar/style.css) & [`~/dotfiles/.config/waybar/style.css`](file:///home/vicky/dotfiles/.config/waybar/style.css)

---

## 19. Rofi-Themed Minimalist Power Menu
- **Goal**: Replace the bloated, broken-layout `wlogout` fullscreen overlay with a compact, elegant power menu matching the exact visual aesthetics, color palette, fonts, and border styles of the Rofi application launcher (`rofi`).
- **Positioning Requirement**: Placed at the top-right corner. When Waybar is active, it sits directly underneath Waybar on the right side (`y-offset: 10px`, `x-offset: -10px`); when Waybar is toggled off, it cleanly anchors 10px from the top-right corner of the monitor.
- **Rofi Theme Implementation**:
  - Created [`~/.config/rofi/powermenu.rasi`](file:///home/vicky/.config/rofi/powermenu.rasi):
    - Imports `@import "colors.rasi"` for seamless dynamic theme consistency.
    - Configured with `location: northeast; anchor: northeast; x-offset: -10px; y-offset: 10px; width: 200px;`.
    - Features a 10px rounded border (`border-radius: 10px`), 1px outline with `@border-color`, translucent background (`@bg`), and padding matching Rofi menus.
    - Excludes the inputbar to render as a sleek floating context menu card.
    - Enabled `hover-select: true`, `click-to-exit: true`, and instant single-click activation via `me-accept-entry: "MousePrimary"`.
    - Styled selected elements with `@bg-selected`, 1px `@border-color` border, and `@border-color` text highlight matching the application launcher.
- **Power Menu Script**:
  - Created [`~/.config/hypr/scripts/powermenu.sh`](file:///home/vicky/.config/hypr/scripts/powermenu.sh):
    - Implements toggle logic: closing Rofi immediately if already open.
    - Presents 6 options with clean Nerd Font icons:
      - `󰌾  Lock` -> `hyprlock`
      - `󰤄  Suspend` -> `systemctl suspend`
      - `󰒲  Hibernate` -> `systemctl hibernate`
      - `󰍃  Logout` -> `hyprctl dispatch exit`
      - `󰑓  Reboot` -> `systemctl reboot`
      - `⏻  Shutdown` -> `systemctl poweroff`
- **Callers & Integration**:
  - Updated Waybar's `custom/power` button in [`~/.config/waybar/config.jsonc`](file:///home/vicky/.config/waybar/config.jsonc) to execute `powermenu.sh`.
  - Updated Hyprland's power menu keybind (<kbd>Super</kbd>+<kbd>`</kbd> / `GRAVE`) in [`~/.config/hypr/keybinds.lua`](file:///home/vicky/.config/hypr/keybinds.lua) to execute `powermenu.sh`.
  - Updated [`~/.config/hypr/scripts/wlogout.sh`](file:///home/vicky/.config/hypr/scripts/wlogout.sh) as a backwards-compatibility wrapper executing `powermenu.sh`.
- **Files Modified / Created**:
  - [`~/.config/rofi/powermenu.rasi`](file:///home/vicky/.config/rofi/powermenu.rasi) & [`~/dotfiles/.config/rofi/powermenu.rasi`](file:///home/vicky/dotfiles/.config/rofi/powermenu.rasi)
  - [`~/.config/hypr/scripts/powermenu.sh`](file:///home/vicky/.config/hypr/scripts/powermenu.sh) & [`~/dotfiles/.config/hypr/scripts/powermenu.sh`](file:///home/vicky/dotfiles/.config/hypr/scripts/powermenu.sh)
  - [`~/.config/hypr/scripts/wlogout.sh`](file:///home/vicky/.config/hypr/scripts/wlogout.sh) & [`~/dotfiles/.config/hypr/scripts/wlogout.sh`](file:///home/vicky/dotfiles/.config/hypr/scripts/wlogout.sh)
  - [`~/.config/waybar/config.jsonc`](file:///home/vicky/.config/waybar/config.jsonc) & [`~/dotfiles/.config/waybar/config.jsonc`](file:///home/vicky/dotfiles/.config/waybar/config.jsonc)
  - [`~/.config/hypr/keybinds.lua`](file:///home/vicky/.config/hypr/keybinds.lua) & [`~/dotfiles/.config/hypr/keybinds.lua`](file:///home/vicky/dotfiles/.config/hypr/keybinds.lua)

---

## 20. Quickshell Keybindings Cheatsheet & Real-Time Search Visualizer (<kbd>SUPER</kbd> + <kbd>K</kbd>)
- **Goal**: Create an interactive, keyboard-centric keybindings cheatsheet matching the exact design aesthetic, typography, borders, and animations of the Quickshell Settings window, featuring instant real-time search and an in-place isolate-and-dismiss animation.
- **Window Geometry & Positioning**:
  - Exact dimensions: **750 x 600 px**.
  - Position: Precisely centered on screen via `PerspectivePanel` with 3D tilt, parallax hover, and smooth entrance/exit animations.
  - Layer & Focus: `WlrLayershell.layer: WlrLayer.Overlay` with `WlrKeyboardFocus.Exclusive` when open so keyboard events are immediately captured without requiring a mouse click.
- **Aesthetic Matching Settings**:
  - Translucent card background (`Theme.bg`), 1px outline with `Theme.accent`, 10px rounded corners (`Theme.radius`).
  - Cyberpunk corner brackets: top-left (40x2 & 2x40) and bottom-right (40x2 & 2x40) in `Theme.accent2`.
  - Top handle pill with centered accent dots.
  - Close button ("✕") with hover danger color highlight.
  - Fonts: `Theme.fontFamily` ("JetBrains Mono") and `Theme.iconFont` ("JetBrainsMono Nerd Font").
- **Two-Column Layout**:
  - **Left Column** (`KEYBIND`, 280px): Renders key combinations in dark keyboard pill badges with `Theme.accent2` highlights when focused.
  - **Right Column** (`DESCRIPTION`): Displays clear functional explanations alongside category tags (`Launchers`, `Windows`, `System`, `Navigation`, `Media`, `Hardware`).
- **Keyboard-Centric Automatic Search**:
  - Immediately upon opening with <kbd>SUPER</kbd> + <kbd>K</kbd>, typing anywhere feeds directly into the search bar at the top with zero mouse clicks needed.
  - Dynamically filters all keybindings in real-time across keys, descriptions, and categories with a match count badge (`N matches`).
  - Arrow navigation: <kbd>↑</kbd> and <kbd>↓</kbd> navigate between filtered rows, with smooth list auto-scrolling.
  - Pressing <kbd>Escape</kbd> clears the search query if text is present, or closes the window if empty.
- **Isolate-in-Place & Fade-Away Sequence**:
  - When pressing <kbd>Enter</kbd> (or clicking a row):
    - The entire window frame, background, corner brackets, header, search bar, and all other non-selected rows immediately vanish (`opacity: 0` in 100ms).
    - The chosen row remains in its **exact same place** and **exact same size** on the screen with an opaque dark background (`Theme.bgPanel`) and `Theme.accent2` glowing border for crystal-clear readability over background windows.
    - It holds in place for **1.0 second**, then smoothly dissolves away over 350ms to close the window.
    - **Flicker Fix**: Eliminated state race conditions during layer unmapping so the full window never flashes back before vanishing.
- **Keybinding & System Integration**:
  - Mapped <kbd>SUPER</kbd> + <kbd>K</kbd> in [`~/.config/hypr/keybinds.lua`](file:///home/vicky/.config/hypr/keybinds.lua) to `qs ipc call keybinds toggle`.
  - Re-mapped the old vim focus up binding to <kbd>SUPER</kbd> + <kbd>Up</kbd> so <kbd>SUPER</kbd> + <kbd>K</kbd> is completely dedicated to the keybindings visualizer.
  - Mounted `KeybindsWindow {}` in [`~/.config/quickshell/shell.qml`](file:///home/vicky/.config/quickshell/shell.qml).
- **Files Modified / Created**:
  - [`~/.config/quickshell/KeybindsWindow.qml`](file:///home/vicky/.config/quickshell/KeybindsWindow.qml) & [`~/dotfiles/.config/quickshell/KeybindsWindow.qml`](file:///home/vicky/dotfiles/.config/quickshell/KeybindsWindow.qml)
  - [`~/.config/quickshell/shell.qml`](file:///home/vicky/.config/quickshell/shell.qml) & [`~/dotfiles/.config/quickshell/shell.qml`](file:///home/vicky/dotfiles/.config/quickshell/shell.qml)
  - [`~/.config/hypr/keybinds.lua`](file:///home/vicky/.config/hypr/keybinds.lua) & [`~/dotfiles/.config/hypr/keybinds.lua`](file:///home/vicky/dotfiles/.config/hypr/keybinds.lua)

---

## 21. Laptop Lid Closing Behavior (Screen Off + Hyprlock, No Sleep)
- **Goal**:
  - Configure default laptop lid behavior across the dotfiles so closing the lid **never triggers system sleep/suspend**.
  - Closing the lid turns off the internal display and locks the session with `hyprlock`.
  - If any external display is connected, it remains completely active and intact (clamshell mode).
  - Opening the lid instantly turns on the internal screen with `hyprlock` ready for unlock.
  - Portable across fresh installations via `install.sh` without requiring hardware-specific sleep fixes.
- **Hyprland Lid Switch Implementation**:
  - Created [`~/.config/hypr/scripts/lid-handler.sh`](file:///home/vicky/.config/hypr/scripts/lid-handler.sh):
    - Dynamically detects the internal laptop display (matching `eDP-*`) and counts active external monitors.
    - **Lid Close**:
      - If external monitor(s) connected: powers off only the internal display via `hl.dsp.dpms("off", ...)`, leaving external displays intact.
      - If standalone laptop: launches `hyprlock` in background and powers off the internal display via `hl.dsp.dpms("off", ...)`.
    - **Lid Open**:
      - Instantly powers back on the internal display via `hl.dsp.dpms("on", ...)`. Ensures `hyprlock` is running if standalone, presenting the user with the lock screen immediately.
  - Registered switch bindings in [`~/.config/hypr/keybinds.lua`](file:///home/vicky/.config/hypr/keybinds.lua):
    - `switch:on:Lid Switch` &rarr; `lid-handler.sh close` (`locked = true`)
    - `switch:off:Lid Switch` &rarr; `lid-handler.sh open` (`locked = true`)
  - Configured DPMS auto-wake in [`~/.config/hypr/hyprland.lua`](file:///home/vicky/.config/hypr/hyprland.lua) (`mouse_move_enables_dpms = true`, `key_press_enables_dpms = true`).
  - Added user-level inhibitor to Hyprland autostart (`systemd-inhibit --what=handle-lid-switch`) to prevent logind from suspending on lid close.
- **Fresh Install Automation (`install.sh`)**:
  - Added systemd-logind drop-in configuration (`/etc/systemd/logind.conf.d/hyprland-lid.conf` with `HandleLidSwitch=ignore`) directly in `install.sh` so any fresh installation automatically sets this behavior by default.
- **Files Modified / Created**:
  - [`~/.config/hypr/scripts/lid-handler.sh`](file:///home/vicky/.config/hypr/scripts/lid-handler.sh) & [`~/Tegmentum-OS/.config/hypr/scripts/lid-handler.sh`](file:///home/vicky/Tegmentum-OS/.config/hypr/scripts/lid-handler.sh)
  - [`~/.config/hypr/hyprland.lua`](file:///home/vicky/.config/hypr/hyprland.lua) & [`~/Tegmentum-OS/.config/hypr/hyprland.lua`](file:///home/vicky/Tegmentum-OS/.config/hypr/hyprland.lua)
  - [`~/.config/hypr/keybinds.lua`](file:///home/vicky/.config/hypr/keybinds.lua) & [`~/Tegmentum-OS/.config/hypr/keybinds.lua`](file:///home/vicky/Tegmentum-OS/.config/hypr/keybinds.lua)
  - [`~/Tegmentum-OS/install.sh`](file:///home/vicky/Tegmentum-OS/install.sh)

---

## 22. Persistent Per-Workspace Layout Toggling (Dwindle ⇄ Scrolling)
- **Goal**:
  - Allow toggling the active workspace layout between `dwindle` (binary split) and `scrolling` (horizontal tape layout) via a dedicated shortcut.
  - Changes must be isolated per workspace and persistent across reboots.
- **Implementation**:
  - Created [`~/.config/hypr/scripts/toggle-workspace-layout.py`](file:///home/vicky/.config/hypr/scripts/toggle-workspace-layout.py):
    - Reads active workspace ID/name and `tiledLayout` via `hyprctl activeworkspace -j`.
    - Toggles between `dwindle` and `scrolling`.
    - Dynamically evaluates and applies the layout to the active workspace in real time: `hyprctl eval "hl.workspace_rule({ workspace = '...', layout = '...' })"`.
    - Persists the mapping into [`~/.config/hypr/workspace-layouts.lua`](file:///home/vicky/.config/hypr/workspace-layouts.lua) and mirrors to `~/Tegmentum-OS/.config/hypr/workspace-layouts.lua`.
    - Sends synchronous Dunst notification (`notify-send`) and Hyprland notification badge (`hyprctl notify`).
  - Added split-out loader `pcall(require, "workspace-layouts")` in [`~/.config/hypr/hyprland.lua`](file:///home/vicky/.config/hypr/hyprland.lua) so that all persistent rules load automatically on boot.
  - Bound <kbd>Super</kbd> + <kbd>L</kbd> in [`~/.config/hypr/keybinds.lua`](file:///home/vicky/.config/hypr/keybinds.lua).
  - Added <kbd>Super</kbd> + <kbd>L</kbd> to the live cheatsheet in [`~/.config/quickshell/KeybindsWindow.qml`](file:///home/vicky/.config/quickshell/KeybindsWindow.qml).
- **Files Modified / Created**:
  - [`~/.config/hypr/scripts/toggle-workspace-layout.py`](file:///home/vicky/.config/hypr/scripts/toggle-workspace-layout.py)
  - [`~/.config/hypr/workspace-layouts.lua`](file:///home/vicky/.config/hypr/workspace-layouts.lua)
  - [`~/.config/hypr/hyprland.lua`](file:///home/vicky/.config/hypr/hyprland.lua)
  - [`~/.config/hypr/keybinds.lua`](file:///home/vicky/.config/hypr/keybinds.lua)
  - [`~/.config/quickshell/KeybindsWindow.qml`](file:///home/vicky/.config/quickshell/KeybindsWindow.qml)
  - [`~/Tegmentum-OS/README.md`](file:///home/vicky/Tegmentum-OS/README.md)

---

## 24. Arrow-Key Navigation, Super+L Layout Manager, Floating Window Alt-Tab Fix & Window Resizing
- **Goal**:
  1. Window Navigation: Pure arrow-key window focus and movement (<kbd>Super</kbd> + <kbd>←/→/↑/↓</kbd> and <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>←/→/↑/↓</kbd>), removing vim keys (<kbd>H</kbd>/<kbd>J</kbd>/<kbd>K</kbd>/<kbd>L</kbd>).
  2. Layout Management: Rebind persistent workspace layout toggle to <kbd>Super</kbd> + <kbd>L</kbd>.
  3. Floating Windows Focus & Elevation Fix: Fix floating windows not focusing or coming up when cycling with <kbd>Alt</kbd> + <kbd>Tab</kbd>.
  4. Window Resizing Keybinds: Full standard (50px) and fine-grained (10px) width and height resizing via <kbd>+</kbd> and <kbd>-</kbd>.
- **Root Cause & Fix for Floating Focus**:
  - Previous configuration ran `hyprctl dispatch bringactivetotop`, which is deprecated and unsupported in modern Hyprland Lua, causing a dispatch error every cycle.
  - Replaced with native Lua dispatchers `hl.dsp.window.alter_zorder({ mode = "top" })` and `hl.dsp.window.bring_to_top()` combined with a 25ms one-shot timer (`hl.timer`) to ensure floating windows rise to the top reliably.
  - Fixed reverse cycling argument from `next = false` to Hyprland's native `forward = false`.
- **Window Resizing Specifications**:
  - Width standard (50px): <kbd>Super</kbd> + <kbd>+</kbd> (expand) / <kbd>-</kbd> (shrink)
  - Height standard (50px): <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>+</kbd> (expand) / <kbd>-</kbd> (shrink)
  - Width precise (10px): <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>+</kbd> (expand) / <kbd>-</kbd> (shrink)
  - Height precise (10px): <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>Alt</kbd> + <kbd>+</kbd> (expand) / <kbd>-</kbd> (shrink)
  - Full keypad support (`KP_Add`, `KP_Subtract`) and symbol variations (`=`, `+`, `-`, `_`) with `{ repeating = true }`.
- **Window Split Toggle**:
  - Bound <kbd>Super</kbd> + <kbd>J</kbd> to `hl.dsp.layout("togglesplit")` allowing instantaneous switching between horizontal and vertical tiling splits for the focused window in dwindle layout.
- **Full Window (Tiled Fullscreen / Maximize)**:
  - Bound <kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>F</kbd> to `hl.dsp.window.fullscreen({ mode = 1 })`, maximizing the active window within the tiling layout to occupy the full workspace while keeping top bars (Waybar) and gaps visible (distinguished from pure fullscreen <kbd>Super</kbd> + <kbd>F</kbd> mode 0).
- **Cheatsheet Sync**:
  - Updated [`~/.config/quickshell/KeybindsWindow.qml`](file:///home/vicky/.config/quickshell/KeybindsWindow.qml) database to display all updated navigation, sizing, split, and full window bindings.

---

## 25. Fullscreen Mode Inheritance During Window Cycling & True Reverse Cycling
- **Goal**:
  1. Fullscreen / Full Window Persistence: When a window is in fullscreen (<kbd>Super</kbd> + <kbd>F</kbd>, mode 0) or full window (<kbd>Super</kbd> + <kbd>Ctrl</kbd> + <kbd>F</kbd>, mode 1), cycling between windows via <kbd>Alt</kbd> + <kbd>Tab</kbd> or arrow keys must automatically preserve and inherit that exact mode instead of exiting to normal tiling.
  2. True Reverse Cycling: Fix <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>Tab</kbd> and <kbd>Alt</kbd> + <kbd>Shift</kbd> + <kbd>`</kbd> cycling in reverse direction rather than forward.
- **Implementation**:
  - Upgraded `focusAndRaise(dispatcher)` in [`~/.config/hypr/keybinds.lua`](file:///home/vicky/.config/hypr/keybinds.lua) to read the initial window's `fullscreen` state (`0` = normal, `1` = full window/maximize, `2` = absolute fullscreen).
  - Automatically re-applies `hl.dsp.window.fullscreen({ mode = 1 })` or `mode = 0` to newly focused windows so navigation keeps the active viewport in full window / fullscreen without disruption.
  - Replaced unsupported `forward = false` argument with Hyprland's native `{ prev = true }` for reverse cycling.
- **Power Menu Shortcut Rebound**:
  - Rebound the rofi power menu from <kbd>Super</kbd> + <kbd>`</kbd> to <kbd>Super</kbd> + <kbd>Esc</kbd>.

---

## 26. Modern Directory Listing with `eza` (Icons, Permissions, Grouped Directories)
- **Goal**: Match the user's secondary laptop terminal setup where `ls` displays rich formatted output with file permissions (`drwxr-xr-x`, `.rw-r--r--`), human-readable sizes (`1.4k`, `-`), owner user, date, Nerd Font icons, and directories grouped first.
- **Aliases Configured** (in `~/.zshrc`, `~/.bashrc`, and `~/Tegmentum-OS/.config/.zshrc`):
  ```bash
  # Listing (using eza with icons and grouped directories to match user setup)
  if command -v eza &>/dev/null; then
    alias ls='eza -l --icons=always --group-directories-first'
    alias ll='eza -la --icons=always --group-directories-first'
    alias la='eza -a --icons=always --group-directories-first'
    alias l='eza -l --icons=always --group-directories-first'
  else
    alias ls='ls --color=auto'
    alias ll='ls -lah --color=auto'
    alias la='ls -A --color=auto'
    alias l='ls -CF --color=auto'
  fi
  ```
- **Files Modified**:
  - [`~/.zshrc`](file:///home/vicky/.zshrc)
  - [`~/.bashrc`](file:///home/vicky/.bashrc)
  - [`~/Tegmentum-OS/.config/.zshrc`](file:///home/vicky/Tegmentum-OS/.config/.zshrc)

---

## 27. Terminal Scrollback Buffer Purging on `clear` & <kbd>Ctrl</kbd> + <kbd>L</kbd>
- **Goal**: When running `clear` (or pressing <kbd>Ctrl</kbd> + <kbd>L</kbd>), completely wipe the screen and flush the terminal scrollback history so scrolling up reveals no residual previous output.
- **Root Cause**: Modern terminal emulators like Kitty only erase the visible viewport when receiving standard ANSI `\033[H\033[2J`, pushing lines into scrollback buffer. Kitty's default terminfo was also missing the `E3` (`\E[3J`) capability, so `/usr/bin/clear` did not clear the scrollback buffer.
- **Implementation**:
  1. **Shell Alias**: Added `alias clear="printf '\033[2J\033[3J\033[H'"` in both `~/.zshrc` and `~/.bashrc`.
  2. **Kitty Configuration**: Added shortcut to [`~/.config/kitty/kitty.conf`](file:///home/vicky/.config/kitty/kitty.conf) and [`~/Tegmentum-OS/.config/kitty/kitty.conf`](file:///home/vicky/Tegmentum-OS/.config/kitty/kitty.conf):
     ```conf
     map ctrl+l combine : clear_terminal scrollback active : send_text normal,application \x0c
     ```
  3. **Terminfo Enhancement**: Compiled `E3=\E[3J,` capability into `~/.terminfo/x/xterm-kitty` so even raw `/usr/bin/clear` invocations in subshells emit `^[[H^[[2J^[[3J`.
