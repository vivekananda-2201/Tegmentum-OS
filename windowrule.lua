-- Floating Terminal Rule
hl.window_rule({
  match = { class = "^floating-terminal$" },
  float = true,
  size = {850, 650},
  center = true,
  
  -- Note: If you prefer a fixed position instead of centered, 
  -- delete `center = true` and uncomment the line below:
  -- move = {120, 90},
})