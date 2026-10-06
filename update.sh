#!/usr/bin/env bash

set -uo pipefail

# Tegmentum-OS updater
#
# Fast-path sync for iterating on the dotfiles after the initial install.sh
# run. Installs any new packages.txt entries, mirrors ~/dotfiles/.config
# into ~/.config, fixes permissions, and regenerates the theme.
#
# Does NOT touch: backups, default shell, PipeWire services, or Papirus
# folders — those are one-time install.sh concerns.
#
# Usage:
#   ./update.sh                 auto-pull latest changes + install new packages + sync + regenerate theme
#   ./update.sh --no-pull       skip pulling latest git changes
#   ./update.sh --dry-run       show what would change, do nothing
#   ./update.sh --skip-packages skip package installation, sync configs only
#   ./update.sh --restart-shell also restart Quickshell (qs)
#
# Install and test:
# chmod +x update.sh
# ./update.sh --dry-run
# Then run:
# ./update.sh

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
SRC="$REPO_DIR/.config"
PACKAGE_FILE="$REPO_DIR/packages.txt"

DRY_RUN=0
RESTART_SHELL=0
SKIP_PACKAGES=0
SKIP_PULL=0

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1; SKIP_PULL=1 ;;
        --restart-shell) RESTART_SHELL=1 ;;
        --skip-packages) SKIP_PACKAGES=1 ;;
        --no-pull|--skip-pull) SKIP_PULL=1 ;;
        *)
            printf '\033[1;31m[ERROR]\033[0m Unknown option: %s\n' "$arg" >&2
            exit 1
            ;;
    esac
done

info()    { printf '\n\033[1;34m[INFO]\033[0m %s\n' "$1"; }
success() { printf '\n\033[1;32m[DONE]\033[0m %s\n' "$1"; }
warning() { printf '\n\033[1;33m[WARN]\033[0m %s\n' "$1"; }
error()   { printf '\n\033[1;31m[ERROR]\033[0m %s\n' "$1" >&2; }

if [[ "${EUID}" -eq 0 ]]; then
    error "Do not run this script as root."
    exit 1
fi

# --------------------------------------------------
# Auto-update: Pull latest changes from git
# --------------------------------------------------

if [[ "$SKIP_PULL" -eq 0 && "${UPDATE_REEXECED:-0}" -eq 0 ]]; then
    if git -C "$REPO_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        if [[ -n "$(git -C "$REPO_DIR" remote 2>/dev/null)" ]]; then
            info "Checking for repository updates (git pull)..."

            HEAD_BEFORE="$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null || echo "")"

            if git -C "$REPO_DIR" pull --ff-only 2>/dev/null || git -C "$REPO_DIR" pull 2>/dev/null; then
                HEAD_AFTER="$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null || echo "")"

                if [[ -n "$HEAD_BEFORE" && "$HEAD_BEFORE" != "$HEAD_AFTER" ]]; then
                    success "Repository updated to latest version."
                    info "Re-executing updater to apply new updates..."
                    export UPDATE_REEXECED=1
                    exec bash "$0" "$@"
                else
                    success "Repository is already up to date."
                fi
            else
                warning "Could not pull updates from remote (offline or local modifications). Continuing with local files..."
            fi
        fi
    fi
fi

if [[ ! -d "$SRC" ]]; then
    error "No .config directory found at $SRC"
    exit 1
fi

# --------------------------------------------------
# Packages
# --------------------------------------------------

UNKNOWN_PACKAGES=()

if [[ "$SKIP_PACKAGES" -eq 1 ]]; then
    info "Skipping package installation (--skip-packages)."
elif [[ "$DRY_RUN" -eq 1 ]]; then
    info "Dry run — skipping package resolution (can be slow); use a real run to check packages."
else
    if ! command -v pacman >/dev/null 2>&1; then
        error "pacman was not found. This updater requires an Arch-based system."
        exit 1
    fi

    if [[ ! -f "$PACKAGE_FILE" ]]; then
        warning "packages.txt not found; skipping package installation."
    elif ! command -v sudo >/dev/null 2>&1; then
        warning "sudo not found; skipping package installation."
    else
        AUR_HELPER=""
        if command -v paru >/dev/null 2>&1; then
            AUR_HELPER="paru"
        elif command -v yay >/dev/null 2>&1; then
            AUR_HELPER="yay"
        fi

        mapfile -t PACKAGES < <(
            grep -vE '^[[:space:]]*(#|$)' "$PACKAGE_FILE"
        )

        OFFICIAL_PACKAGES=()
        AUR_PACKAGES=()

        if [[ "${#PACKAGES[@]}" -eq 0 ]]; then
            warning "packages.txt does not contain any packages."
        else
            info "Checking packages.txt against installed packages..."

            for pkg in "${PACKAGES[@]}"; do
                if pacman -Qi "$pkg" >/dev/null 2>&1; then
                    continue  # already installed, nothing to do
                elif pacman -Si "$pkg" >/dev/null 2>&1; then
                    OFFICIAL_PACKAGES+=("$pkg")
                elif [[ -n "$AUR_HELPER" ]] && "$AUR_HELPER" -Si "$pkg" >/dev/null 2>&1; then
                    AUR_PACKAGES+=("$pkg")
                else
                    UNKNOWN_PACKAGES+=("$pkg")
                fi
            done

            if [[ "${#OFFICIAL_PACKAGES[@]}" -eq 0 && "${#AUR_PACKAGES[@]}" -eq 0 ]]; then
                success "All packages already installed."
            fi

            if [[ "${#OFFICIAL_PACKAGES[@]}" -gt 0 ]]; then
                info "Installing new official-repo packages: ${OFFICIAL_PACKAGES[*]}"
                if sudo pacman -S --needed --noconfirm "${OFFICIAL_PACKAGES[@]}"; then
                    success "Official-repo packages installed."
                else
                    warning "pacman reported an error installing one or more packages. Continuing anyway."
                fi
            fi

            if [[ "${#AUR_PACKAGES[@]}" -gt 0 ]]; then
                if [[ -n "$AUR_HELPER" ]]; then
                    info "Installing new AUR packages with $AUR_HELPER: ${AUR_PACKAGES[*]}"
                    if "$AUR_HELPER" -S --needed --noconfirm "${AUR_PACKAGES[@]}"; then
                        success "AUR packages installed."
                    else
                        warning "$AUR_HELPER reported an error installing one or more packages. Continuing anyway."
                    fi
                else
                    warning "No AUR helper found; cannot install: ${AUR_PACKAGES[*]}"
                    warning "Run install.sh once to bootstrap an AUR helper, or install one manually."
                fi
            fi

            if [[ "${#UNKNOWN_PACKAGES[@]}" -gt 0 ]]; then
                warning "Could not resolve the following package(s) in any repo: ${UNKNOWN_PACKAGES[*]}"
                warning "Check the name with 'pacman -Ss <name>' or https://aur.archlinux.org, then fix packages.txt."
            fi
        fi
    fi
fi

# --------------------------------------------------
# Dry run: show config differences, touch nothing
# --------------------------------------------------

if [[ "$DRY_RUN" -eq 1 ]]; then
    info "Dry run — showing config differences (repo vs. installed), nothing will be written:"
    if command -v diff >/dev/null 2>&1; then
        diff -rq "$SRC" "$CONFIG_DIR" 2>/dev/null | grep -v '^Only in .*: \.git$' || true
    else
        warning "diff not found; cannot show a dry-run preview."
    fi
    printf '\n'
    info "Re-run without --dry-run to apply."
    exit 0
fi

# --------------------------------------------------
# Sync
# --------------------------------------------------

info "Syncing ~/dotfiles/.config -> ~/.config ..."
cp -a "$SRC/." "$CONFIG_DIR/"
success "Config files synced."

info "Fixing executable permissions..."
find "$CONFIG_DIR" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \;
success "Permissions fixed."

# --------------------------------------------------
# Wallpapers
# --------------------------------------------------

if [[ -d "$REPO_DIR/Wallpapers" ]]; then
    info "Syncing wallpapers to ~/Pictures/Wallpapers..."
    mkdir -p "$HOME/Pictures/Wallpapers"
    cp -a "$REPO_DIR/Wallpapers/." "$HOME/Pictures/Wallpapers/"

    if [[ ! -f "$HOME/.cache/current_wallpaper" && -f "$HOME/Pictures/Wallpapers/Main/wallhaven-gw5qq7.jpg" ]]; then
        mkdir -p "$HOME/.cache"
        echo "$HOME/Pictures/Wallpapers/Main/wallhaven-gw5qq7.jpg" > "$HOME/.cache/current_wallpaper"
    fi

    success "Wallpapers synced."
fi

# --------------------------------------------------
# Regenerate theme
# --------------------------------------------------

if command -v python3 >/dev/null 2>&1; then
    info "Regenerating theme from current palette..."
    if python3 "$CONFIG_DIR/tegmentum/bin/theme.py" apply; then
        success "Theme regenerated and consumers reloaded (Kitty, Waybar)."
    else
        error "Theme regeneration failed — check the error above."
        error "Configs on disk may be a mix of old and new; run 'theme apply' again once fixed."
        exit 1
    fi
else
    warning "python3 not found; theme was NOT regenerated."
fi

# --------------------------------------------------
# Manual-reload reminders (things that can't be scripted)
# --------------------------------------------------

printf '\n'
warning "GTK apps (Thunar) cache colors per-process. If Thunar looks stale: thunar -q && thunar"
warning "Rofi and wlogout re-read their CSS on next launch — no action needed."
warning "Hyprlock re-reads its config on next lock — no action needed."

if [[ "$RESTART_SHELL" -eq 1 ]]; then
    info "Restarting Quickshell (qs)..."
    pkill qs 2>/dev/null || true
    sleep 1
    nohup qs >/dev/null 2>&1 &
    disown
    success "Quickshell restarted."
else
    warning "Quickshell (qs) was NOT restarted. Only needed if you edited a .qml file"
    warning "  (routine theme/color changes do not need this) — re-run with --restart-shell if so."
fi

if [[ "${#UNKNOWN_PACKAGES[@]}" -gt 0 ]]; then
    printf '\n'
    warning "Unresolved packages (install manually): ${UNKNOWN_PACKAGES[*]}"
fi

printf '\n'
success "Update complete!"
