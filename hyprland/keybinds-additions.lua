-- Replace the lock binds in hyprland/keybinds.lua with these
create_bind(vars.kbLock, hl.dsp.exec_cmd("qs -c lockscreen ipc call lockscreen lock"))

-- Restore lock
create_bind(vars.kbRestoreLock, function()
    hl.dispatch(hl.dsp.exec_cmd("qs -c lockscreen -n -d"))
    hl.dispatch(hl.dsp.exec_cmd("qs -c lockscreen ipc call lockscreen lock"))
end)

-- Wi-Fi panel (uthman_dotfiles Quickshell module)
create_bind("SUPER + H", hl.dsp.exec_cmd("qs -c wifi-panel ipc call wifi toggle"))

-- Notification island
create_bind("SUPER + SHIFT + N", hl.dsp.exec_cmd("qs -c notif-island ipc call island toggle"))
