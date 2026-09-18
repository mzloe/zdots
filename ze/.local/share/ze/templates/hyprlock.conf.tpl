# Sourced by ~/.config/hypr/hyprlock.conf. Wallpaper = the current desktop one.
$accent = rgb({{ accent_strip }})
$foreground = rgb({{ foreground_strip }})
$background = rgb({{ background_strip }})
$muted = rgb({{ muted_strip }})
$red = rgb({{ red_strip }})
$font = JetBrainsMono Nerd Font

general {
    hide_cursor = true
    ignore_empty_input = true
}

animations {
    enabled = true
    fade_in = 300, easeOutQuint
    fade_out = 300, easeOutQuint
}

background {
    monitor =
    path = $HOME/.config/ze/current/background
    color = $background
    blur_passes = 2
    blur_size = 6
    brightness = 0.8
    vibrancy = 0.15
}

label {
    monitor =
    text = $TIME
    color = $foreground
    font_size = 96
    font_family = $font
    position = 0, 160
    halign = center
    valign = center
}

label {
    monitor =
    text = cmd[update:60000] date +"%A, %d %B"
    color = $foreground
    font_size = 20
    font_family = $font
    position = 0, 70
    halign = center
    valign = center
}

input-field {
    monitor =
    size = 320, 52
    outline_thickness = 2
    dots_size = 0.25
    dots_spacing = 0.3
    dots_center = true
    outer_color = $accent
    inner_color = $background
    font_color = $foreground
    font_family = $font
    fade_on_empty = false
    placeholder_text = <span foreground="##{{ muted_strip }}">Password</span>
    check_color = $muted
    fail_color = $red
    fail_text = <i>$FAIL ($ATTEMPTS)</i>
    capslock_color = $red
    rounding = 12
    position = 0, -40
    halign = center
    valign = center
}
