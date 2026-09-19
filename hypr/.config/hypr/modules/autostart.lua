-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function()
	hl.exec_cmd("waybar")
	hl.exec_cmd("swaync")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("~/.local/bin/ze bg restore") -- starts awww-daemon and sets the wallpaper
	hl.exec_cmd("systemctl --user start hyprpolkitagent")
	hl.exec_cmd("wl-clip-persist --clipboard regular --all-mime-type-regex '^(?!x-kde-passwordManagerHint).+'") -- keep the clipboard after its window closes, skip KeePassXC
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
