-- Add inside your existing execs block in hyprland/execs.lua

-- Standalone Wi-Fi panel (live throughput + speedtest)
hl.exec_cmd("qs -c wifi-panel -n -d")

-- Notification island (top center)
hl.exec_cmd("qs -c notif-island -n -d")

-- Wallpaper clock (frosted time on the background)
hl.exec_cmd("qs -c wall-clock -n -d")

-- multimind-ux lockscreen design
hl.exec_cmd("qs -c lockscreen -n -d")
