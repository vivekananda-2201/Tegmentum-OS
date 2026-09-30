-- Extra autostart processes.
-- o.launch_on_start("my-service")

hl.on("hyprland.start", function()
  -- Your other startup apps (waybar, hyprpaper, etc.)
  
  -- Start the floating terminal
  os.execute("sleep 1")
  hl.exec_cmd("kitty --class floating-terminal")
end)
