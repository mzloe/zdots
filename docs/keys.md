# Keys and commands

`ALT` is the main modifier, `SUPER` the second. Everything below is in
`hypr/.config/hypr/modules/keybinds.lua`, and the `ze` commands are in
`ze/.local/bin/ze`.

## Theme and wallpaper

| Key | Command | What happens |
| --- | --- | --- |
| `ALT + SHIFT + T` | `ze theme pick` | a carousel of theme previews. Same key again closes it |
| `ALT + SHIFT + W` | `ze bg pick` | a carousel of the theme's wallpapers, then a question: Desktop, Login screen or Both |
| `SUPER + W` | `ze bg next` | the next wallpaper. Add `--login` or `--both` for the login screen |
| | `ze theme set <name>` | apply a theme. `"Tokyo Night"` and `tokyo-night` both work |

In a carousel: arrows or Tab move, typing filters, Enter applies, Esc closes.

## Screen and clipboard

| Key | What happens |
| --- | --- |
| `SUPER + L` | lock the screen |
| `Print` | screenshot the monitor under the cursor, then Flameshot's editor |
| `SHIFT + Print` | pick a region first, then the editor |
| `SUPER + V` | clipboard history, text and images. Same key again closes it |

In the clipboard history: typing filters, Enter pastes into the window
underneath, Shift+Enter only copies, Ctrl+Enter opens an image in imv, Delete
removes the entry. Shift+Delete or the Clear history button wipes everything
after a Yes/No prompt. Copies from KeePassXC are never recorded. cliphist
keeps its default of 750 entries. The clipboard survives closing the window
you copied from, which Wayland does not do on its own; wl-clip-persist keeps
a copy and serves it.

## Apps

| Key | Opens |
| --- | --- |
| `ALT + RETURN` | ghostty |
| `ALT + F` | Thunar |
| `ALT + B` | Brave |
| `ALT + SHIFT + B` | Zen |
| `ALT + SPACE` | the launcher (rofi drun) |

Also: `ALT + SHIFT + SPACE` runs a command (rofi run), `ALT + T` hides or
shows the bar, `ALT + N` opens the notification centre.

## Windows

| Key | What happens |
| --- | --- |
| `ALT + H / J / K / L` | focus left, down, up, right |
| `ALT + SHIFT + H / J / K / L` | move the window that way |
| `ALT + 1` to `ALT + 0` | go to that workspace. Add `SHIFT` to send the window there |
| `ALT + W` | close the window |
| `ALT + V` / `ALT + M` | float / maximise |

Also: `ALT + S` shows the scratchpad workspace (`ALT + SHIFT + S` sends a
window to it), `ALT + P` pseudo-tiles, `SUPER + J` toggles the split, `ALT`
plus a mouse button drags (left) or resizes (right), and `SUPER + M` leaves
Hyprland.

## Every ze command

```
ze theme set <name> | list | pick | current | sync | color <key>|--all
ze bg    set <file> [--login | --both] | next [--login | --both] | pick | restore
ze install [--no-packages | --stow | --system] [theme-name]
```

- `ze theme sync` pulls new themes from omarchy and shows you the diff. See
  [customizing.md](customizing.md#pull-omarchys-new-themes).
- `ze theme color --all` prints the current theme's full resolved palette.
- `ze bg restore` runs at login and puts the remembered wallpaper back.
- `ze install` is `install.sh`. The flags are in [install.md](install.md).
