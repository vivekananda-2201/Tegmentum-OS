-- Docs: https://wiki.hypr.land/Configuring/Basics/Window-Rules/

hl.layer_rule({
	match = { namespace = "rofi" },
	blur = true,
	ignore_alpha = 0.15,
})

-- Opacity rules: 90% for all windows except fullscreen
hl.window_rule({
	match = { class = ".*" },
	opacity = "1.0 override",
})

hl.window_rule({
	match = { class = "^(kitty|floating-terminal)$" },
	suppress_event = "maximize",
})

hl.window_rule({
	match = { class = ".*", fullscreen = true },
	opacity = "1.0 override",
})

hl.window_rule({
	name = "float-pavucontrol",
	match = { class = "^(pavucontrol)$" },
	float = true,
})

hl.window_rule({
	name = "float-nm-connection-editor",
	match = { class = "^(nm-connection-editor)$" },
	float = true,
})

hl.window_rule({
	name = "float-blueman-manager",
	match = { class = "^(blueman-manager)$" },
	float = true,
})

hl.window_rule({
	name = "file-chooser-portal",
	match = { class = "^(xdg-desktop-portal-gtk)$" },
	float = true,
	size = { 950, 750 },
	center = true,
})

hl.window_rule({
	name = "float-file-dialogs-by-title",
	match = {
		title = "^(Open File|Open Files|Save File|Save Files|Save As|Select a File|Choose Files|All Files|Select Folder|Open Folder|File Upload).*",
	},
	float = true,
	size = { 950, 750 },
	center = true,
})

-- Floating Terminal Rule
hl.window_rule({
	name = "floating-terminal",
	match = { class = "^(floating-terminal)$" },
	float = true,
	size = { 850, 650 },
	center = true,
	suppress_event = "maximize",

	-- Note: If you prefer a fixed position instead of centered,
	-- delete `center = true` and uncomment the line below:
	-- move = {120, 90},
})
