#!/usr/bin/env bash
# ~/.config/hypr/scripts/launch-quickshell.sh
# Singleton launcher for Quickshell ensuring only 1 instance can ever run

if pgrep -x qs >/dev/null 2>&1; then
    exit 0
fi

# Acquire flock on runtime lockfile to prevent concurrent execution races
(
    flock -n 200 || exit 0

    if ! pgrep -x qs >/dev/null 2>&1; then
        systemctl --user reset-failed quickshell >/dev/null 2>&1 || true
        systemd-run --user --unit=quickshell qs >/dev/null 2>&1 || (nohup qs >/dev/null 2>&1 &)
    fi
) 200>"${XDG_RUNTIME_DIR:-/tmp}/quickshell-launch.lock"
