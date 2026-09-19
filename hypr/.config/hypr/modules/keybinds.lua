---------------------
---- KEYBINDINGS ----
---------------------

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more

-- Apps -------------------------------------------------------------------
hl.bind(MAIN_MOD .. " + RETURN", hl.dsp.exec_cmd(TERMINAL))
hl.bind(MAIN_MOD .. " + F", hl.dsp.exec_cmd(FILE_MANAGER))
hl.bind(MAIN_MOD .. " + B", hl.dsp.exec_cmd(MAIN_BROWSER))
hl.bind(MAIN_MOD .. " + SHIFT + B", hl.dsp.exec_cmd(SECOND_BROWSER))
hl.bind(MAIN_MOD .. " + T", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle-waybar.sh"))
hl.bind(MAIN_MOD .. " + N", hl.dsp.exec_cmd("swaync-client -t"))
hl.bind(MAIN_MOD .. " + SPACE", hl.dsp.exec_cmd(LAUNCHER))
hl.bind(MAIN_MOD .. " + SHIFT + SPACE", hl.dsp.exec_cmd(RUNNER))

-- Theme and wallpaper ----------------------------------------------------
hl.bind(MAIN_MOD .. " + SHIFT + T", hl.dsp.exec_cmd("~/.local/bin/ze theme pick"))
hl.bind(MAIN_MOD .. " + SHIFT + W", hl.dsp.exec_cmd("~/.local/bin/ze bg pick"))
hl.bind(SECOND_MOD .. " + W", hl.dsp.exec_cmd("~/.local/bin/ze bg next"))
hl.bind(SECOND_MOD .. " + L", hl.dsp.exec_cmd("loginctl lock-session"))

-- exit-hyprland ----------------------------------------------------------
hl.bind(
	SECOND_MOD .. " + M",
	hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'")
)

-- Windows manipulation ----------------------------------------------------
hl.bind(MAIN_MOD .. " + w", hl.dsp.window.close())
hl.bind(MAIN_MOD .. " + P", hl.dsp.window.pseudo())
hl.bind(SECOND_MOD .. " + J", hl.dsp.layout("togglesplit")) -- dwindle only

-- Move focus with MAIN_MOD + vim keys
hl.bind(MAIN_MOD .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(MAIN_MOD .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(MAIN_MOD .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(MAIN_MOD .. " + L", hl.dsp.focus({ direction = "right" }))

-- Swap windows with MAIN_MOD + SHIFT + vim keys
hl.bind(MAIN_MOD .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(MAIN_MOD .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(MAIN_MOD .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(MAIN_MOD .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

-- Set float/maximize windows with MAIN_MOD + V/M
hl.bind(MAIN_MOD .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(MAIN_MOD .. " + M", hl.dsp.window.fullscreen({ mode = "maximized" }))

-- Move/resize windows with MAIN_MOD + LMB/RMB and dragging
hl.bind(MAIN_MOD .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(MAIN_MOD .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Workspaces ---------------------------------------------------------------
-- Switch workspaces with MAIN_MOD + [0-9]
-- Move active window to a workspace with MAIN_MOD + SHIFT + [0-9]
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(MAIN_MOD .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(MAIN_MOD .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- special workspace (scratchpad)
hl.bind(MAIN_MOD .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(MAIN_MOD .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with MAIN_MOD + scroll
hl.bind(MAIN_MOD .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(MAIN_MOD .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Laptop multimedia keys for volume and LCD brightness -------------------------
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Screenshots -----------------------------------------------------------
hl.bind("Print", function()
	local mon = hl.get_active_monitor()
	hl.exec_cmd("flameshot screen --number " .. (mon and mon.id or 0) .. " --edit")
end)
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("flameshot gui"))
