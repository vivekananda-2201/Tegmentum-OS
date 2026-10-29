-- ~/.config/hypr/hyprland.lua
-- Docs: https://wiki.hypr.land/Configuring/Start/

---- MY PROGRAMS ----

mainMod = "SUPER"
terminal = "kitty"
menu = "rofi -show drun"
fileManager = "nautilus --new-window"
browser = "firefox"

---- AUTOSTART ----

local function isLidClosed()
	local p = io.popen("grep -oE 'open|closed' /proc/acpi/button/lid/*/state 2>/dev/null | head -n 1")
	if p then
		local s = p:read("*l")
		p:close()
		return s == "closed"
	end
	return false
end

hl.on("hyprland.start", function()
	-- Sync DBus and systemd activation environment
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP QT_QPA_PLATFORM QT_QPA_PLATFORMTHEME")
	systemd_env = "systemctl --user set-environment QT_QPA_PLATFORM=wayland QT_QPA_PLATFORMTHEME=xdgdesktopportal"
	hl.exec_cmd(systemd_env)

	-- Check initial lid and monitor state only if starting session with lid closed (docked clamshell)
	if isLidClosed() then
		hl.exec_cmd("bash " .. os.getenv("HOME") .. "/.config/hypr/scripts/lid-handler.sh check")
	end

	-- Replaced by Quickshell native Bar and Notifications
	-- hl.exec_cmd("waybar")
	-- hl.exec_cmd("dunst")
	hl.exec_cmd("nm-applet")
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")

	hl.exec_cmd("awww-daemon && awww restore")
	hl.exec_cmd("bash " .. os.getenv("HOME") .. "/.config/hypr/scripts/launch-quickshell.sh")
	hl.exec_cmd("systemd-inhibit --what=handle-lid-switch --who=Hyprland --why='Handled by Hyprland' --mode=block sleep infinity")
end)

-- Re-check clamshell state when displays change, only if lid is closed
hl.on("monitor.layout_changed", function()
	if isLidClosed() then
		hl.exec_cmd("bash " .. os.getenv("HOME") .. "/.config/hypr/scripts/lid-handler.sh check")
	end
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
