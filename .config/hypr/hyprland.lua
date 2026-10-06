-- ~/.config/hypr/hyprland.lua
-- Docs: https://wiki.hypr.land/Configuring/Start/

---- MY PROGRAMS ----

mainMod = "SUPER"
terminal = "kitty"
menu = "rofi -show drun"
fileManager = "nautilus --new-window"
browser = "brave"

---- AUTOSTART ----

hl.on("hyprland.start", function()
	-- Sync DBus and systemd activation environment
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP QT_QPA_PLATFORM QT_QPA_PLATFORMTHEME")
	systemd_env = "systemctl --user set-environment QT_QPA_PLATFORM=wayland QT_QPA_PLATFORMTHEME=xdgdesktopportal"
	hl.exec_cmd(systemd_env)

	-- Replaced by Quickshell native Bar and Notifications
	-- hl.exec_cmd("waybar")
	-- hl.exec_cmd("dunst")
	hl.exec_cmd("nm-applet")
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")

	hl.exec_cmd("awww-daemon")
	hl.exec_cmd("sleep 1 && qs")
	hl.exec_cmd("systemd-inhibit --what=handle-lid-switch --who=Hyprland --why='Handled by Hyprland' --mode=block sleep infinity")
end)

---- ENVIRONMENT VARIABLES ----

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "xdgdesktopportal")
hl.env("MOZ_ENABLE_WAYLAND", "1")

---- INPUT ----

hl.config({
	input = {
		kb_layout = "us",
		follow_mouse = 1,
		sensitivity = 0.5,
		touchpad = {
			natural_scroll = false,
			tap_to_click = true,
		},
	},
})

-- LAYOUT
hl.config({
	dwindle = { preserve_split = true },
})
hl.config({
	master = { new_status = "master" },
})

-- MISC
hl.config({
	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		mouse_move_enables_dpms = true,
		key_press_enables_dpms = true,
		focus_on_activate = true,
	},
})

---- SPLIT-OUT FILES ----

require("monitors")
require("keybinds")
require("look")
require("rules")
require("autostart")
pcall(require, "workspace-layouts")
-- HyprMod managed settings
require("hyprland-gui")
