-- ~/.config/hypr/monitors.lua

-- Internal laptop screen (ASUS TUF 16" 1920x1200 @ 144Hz, 1.2 scale)
hl.monitor({
	output = "eDP-1",
	mode = "1920x1200@144.0",
	position = "0x0",
	scale = 1.2,
	vrr = 0,
})

-- Default fallback for any connected external monitor or other displays
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "auto",
})
