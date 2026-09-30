local mainMod = "SUPER"
-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

----------------------------------------------------------------
-- Floating window controls
----------------------------------------------------------------

-- If Omarchy does not already define mainMod, uncomment this:

local moveStep = 40

local function raiseActive()
  -- Bring the currently focused window to the top.
  -- The small delay makes it more reliable after cycling/focusing.
  -- If it feels laggy, replace it with:
  -- hl.dispatch(hl.dsp.exec_cmd("hyprctl dispatch bringactivetotop"))
  hl.dispatch(hl.dsp.exec_cmd("sleep 0.02 && hyprctl dispatch bringactivetotop"))
end

local function focusAndRaise(dispatcher)
  hl.dispatch(dispatcher)
  raiseActive()
end

----------------------------------------------------------------
-- Floating window focus / cycling, bring to top
----------------------------------------------------------------

-- Next floating window
hl.bind("ALT + GRAVE", function()
  focusAndRaise(hl.dsp.window.cycle_next({ floating = true }))
end, { description = "Next floating window" })

-- Previous floating window
hl.bind("ALT + SHIFT + GRAVE", function()
  focusAndRaise(hl.dsp.window.cycle_next({ floating = true, next = false }))
end, { description = "Previous floating window" })

-- Jump directly to a floating window
hl.bind("ALT + F", function()
  focusAndRaise(hl.dsp.focus({ window = "floating" }))
end, { description = "Focus floating window" })

----------------------------------------------------------------
-- Move Floating Window (Arrow Keys + Vim Keys)
----------------------------------------------------------------

-- LEFT
hl.bind(
  mainMod .. " + ALT + CTRL + left",
  hl.dsp.window.move({ x = -moveStep, y = 0, relative = true }),
  { repeating = true },
  { description = "Move floating window left" }
)

hl.bind(
  mainMod .. " + ALT + CTRL + H",
  hl.dsp.window.move({ x = -moveStep, y = 0, relative = true }),
  { repeating = true },
  { description = "Move floating window left" }
)

-- RIGHT
hl.bind(
  mainMod .. " + ALT + CTRL + right",
  hl.dsp.window.move({ x = moveStep, y = 0, relative = true }),
  { repeating = true },
  { description = "Move floating window right" }
)

hl.bind(
  mainMod .. " + ALT + CTRL + L",
  hl.dsp.window.move({ x = moveStep, y = 0, relative = true }),
  { repeating = true },
  { description = "Move floating window right" }
)

-- UP
hl.bind(
  mainMod .. " + ALT + CTRL + up",
  hl.dsp.window.move({ x = 0, y = -moveStep, relative = true }),
  { repeating = true },
  { description = "Move floating window up" }
)

hl.bind(
  mainMod .. " + ALT + CTRL + K",
  hl.dsp.window.move({ x = 0, y = -moveStep, relative = true }),
  { repeating = true },
  { description = "Move floating window up" }
)

-- DOWN
hl.bind(
  mainMod .. " + ALT + CTRL + down",
  hl.dsp.window.move({ x = 0, y = moveStep, relative = true }),
  { repeating = true },
  { description = "Move floating window down" }
)

hl.bind(
  mainMod .. " + ALT + CTRL + J",
  hl.dsp.window.move({ x = 0, y = moveStep, relative = true }),
  { repeating = true },
  { description = "Move floating window down" }
)

----------------------------------------------------------------
-- Hide / unhide floating windows
----------------------------------------------------------------

-- Remove/comment your old SUPER+B browser bind or tiled-cycle bind if present:
-- hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser), { description = "Open the browser" })

hl.bind(
  mainMod .. " + B",
  hl.dsp.exec_cmd("bash " .. os.getenv("HOME") .. "/.config/hypr/scripts/toggle-floats.sh"),
  { description = "Hide/unhide floating windows" }
)


----------------------------------------------------------------
-- Floating Terminal
----------------------------------------------------------------
local terminal = "kitty"

hl.bind(
  mainMod .. " + CTRL + RETURN",
  hl.dsp.exec_cmd(terminal .. " --class floating-terminal"),
  { description = "Open floating terminal" }
)

----------------------------------------------------------------
-- Lid Switch (Display off on close, display on on open - no suspend/lock)
----------------------------------------------------------------
hl.unbind("switch:on:Lid Switch")
hl.unbind("switch:off:Lid Switch")

o.bind("switch:on:Lid Switch", "Turn display off on lid close", "omarchy-lid-handler close", { locked = true })
o.bind("switch:off:Lid Switch", "Turn display on on lid open", "omarchy-lid-handler open", { locked = true })