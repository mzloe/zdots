# What a theme set does

`ze theme set <name>` is one command that ends with every app on the desktop
in the same colours. This page walks through what happens in between, in the
order it happens, and where each file lands.

## The short version

1. The theme directory is copied to `~/.config/ze/current/theme/`.
2. Every template in `templates/` is rendered into that directory with the
   theme's colours.
3. Each app is told to reload. Every app's own config includes the rendered
   file, so the apps never carry a palette of their own.
4. The wallpapers are reset: desktop to the theme's first one, login screen to
   the theme's `login.*` if it has one.

Everything lives under `~/.config/ze/current/`:

```
~/.config/ze/current/
  theme.name          the current theme's name
  theme/              copy of themes/<name> plus the rendered files
  background          symlink to the desktop wallpaper
  login-background    symlink to the login-screen wallpaper
```

## Step 1: staging the theme

`ze theme set` accepts `tokyo-night` as well as `"Tokyo Night"`. It lowercases
the name and turns spaces into hyphens, then looks for
`ze/.local/share/ze/themes/<name>/`.

The theme is first copied to `~/.config/ze/current/next-theme/`, rendered
there, and only then moved into place as `theme/`. A theme set that fails
halfway leaves the previous theme untouched. A lock file stops two theme sets
from running at once, so mashing `ALT + SHIFT + T` twice does no harm.

## Step 2: colours and templates

A theme's palette is `colors.toml`. This is tokyo-night's:

```toml
mode = "dark"

accent = "#7aa2f7"
selection = "#292e42"
muted = "#414868"

background = "#1a1b26"
dark_background = "#13141c"
darker_background = "#0e0e14"
lighter_background = "#24283b"

foreground = "#a9b1d6"
dark_foreground = "#565f89"
light_foreground = "#b4bee6"
bright_foreground = "#c0caf5"

red = "#f7768e"
yellow = "#e0af68"
orange = "#eb927b"
green = "#9ece6a"
cyan = "#449dab"
blue = "#7aa2f7"
magenta = "#ad8ee6"
brown = "#75493d"

bright_red = "#ff7a93"
bright_yellow = "#ff9e64"
bright_green = "#b9f27c"
bright_cyan = "#0db9d7"
bright_blue = "#7da6ff"
bright_magenta = "#bb9af7"
```

Not every key has to be there. `lib/colors.sh` fills in what is missing: a
missing `dark_background` is derived from `background`, `purple` and `magenta`
are aliases of each other, omarchy's older key names still resolve, and `mode`
is guessed from the background's brightness when the file does not say. The
rules are omarchy's, so an omarchy theme resolves to the palette it was
designed with.

To see the full resolved palette of the current theme:

```sh
ze theme color --all
ze theme color accent
```

Templates are the files in `ze/.local/share/ze/templates/`, one per app:

```
btop.theme.tpl   ghostty.conf.tpl  gtk.css.tpl      hyprland.lua.tpl
hyprlock.conf.tpl  rofi.rasi.tpl   sddm.conf.tpl    swaync.css.tpl
t3code.json.tpl  waybar.css.tpl    zed.json.tpl
```

`btop.theme.tpl` becomes `~/.config/ze/current/theme/btop.theme`, and so on.
Inside a template these placeholders work:

| Placeholder | Result |
| --- | --- |
| `{{ accent }}` | `#7aa2f7` |
| `{{ accent_strip }}` | `7aa2f7` |
| `{{ accent_rgb }}` | `122,162,247` |
| `{{ mix background accent 20% }}` | background blended 20% towards accent |
| `{{ hypr_gradient accent muted }}` | a Hyprland gradient string, `muted` as fallback |
| `{{ gradient_start accent }}` | the first colour of that gradient |

A file the theme ships itself wins over the template. If a theme directory
already contains a `btop.theme`, the template is not rendered for it.

## Step 3: telling the apps

Each app is handled by a function in `lib/apply.sh`. Every one of them is a
no-op when the app is not installed, so a program you install next month is
themed on your next theme set.

### Hyprland, ghostty, rofi, waybar, swaync, btop

These include the rendered file from their own config and only need a reload:

| App | Includes | Reload |
| --- | --- | --- |
| Hyprland | `modules/theme.lua` does `dofile()` on the rendered `hyprland.lua` | `hyprctl reload` |
| ghostty | `config-file = ?~/.config/ze/current/theme/ghostty.conf` | `SIGUSR2` |
| rofi | `@import "~/.config/ze/current/theme/rofi.rasi"` | none needed, rofi reads it on launch |
| waybar | `@import "../ze/current/theme/waybar.css"` | `SIGUSR2` |
| swaync | `@import "../ze/current/theme/swaync.css"` | `swaync-client -rs` |
| btop | `color_theme = "current"` | `SIGUSR2` |

btop only finds themes by name inside `~/.config/btop/themes/`, so `ze` keeps
a symlink there called `current.theme` that points at the rendered file.

### Flameshot

Flameshot keeps its settings in `~/.config/flameshot/flameshot.ini` and rewrites
that file itself, so a symlink to a rendered template would not survive the
first settings change. Instead `ze` calls `flameshot config` with the accent as
the main UI colour and the background as the contrast colour. Running
instances watch the ini and repaint. Nothing happens when Flameshot is not
installed.

### GTK

Two things happen. The mode and the icons are set with gsettings
(`color-scheme`, `gtk-theme` to Adwaita or Adwaita-dark, `icon-theme` to the
Yaru variant named in the theme's `icons.theme`) and written to
`~/.config/gtk-3.0/settings.ini` and `gtk-4.0/settings.ini` too, so nwg-look
shows the same thing. Then `gtk.css` in both directories imports the rendered
`gtk.css`, which overrides Adwaita's named colours with the palette.

Honest limit: GTK3 apps such as Thunar have Adwaita's colours compiled in, so
they only follow the light or dark switch and the icon set. The colour
overrides reach GTK4 and libadwaita apps.

A theme that names a Yaru variant the package does not ship (vantablack asks
for Yaru-gray) falls back to plain Yaru.

### Browsers

Brave, Chromium and Chrome read their frame colour from a machine policy:
`/etc/brave/policies/managed/color.json`, `/etc/chromium/...`,
`/etc/opt/chrome/...`. Writing there needs root, so `install.sh` puts a small
root-owned helper at `/usr/local/bin/ze-browser-policy` and a sudoers rule that
allows exactly one call: that helper with a six-digit hex colour as its only
argument. `ze theme set` runs it through `sudo -n`, so there is no password
prompt, and then asks running browsers to reload their policies.

The colour is the theme's `chromium.theme` file if it has one, else the
background. Zen and Firefox have no such policy and only follow the GTK light or
dark switch.

### Neovim

Omarchy themes carry a `neovim.lua` written as a LazyVim plugin spec. `ze`
reads the plugin repo, the colorscheme name and the light or dark background
out of it and writes a tiny `nvim.lua` next to the theme:

```lua
return { repo = "folke/tokyonight.nvim", colorscheme = "tokyonight", background = "dark" }
```

`nvim/.config/nvim/init.lua` reads that file, installs the plugin with
`vim.pack.add`, and applies the colorscheme. Instances that are already open
get a `SIGUSR1` and re-read it. A theme without a `neovim.lua` gets Neovim's
built-in `default` colorscheme with the matching background. Drop a
`neovim.lua` in omarchy's format into the theme directory to give it a real
one.

### Zed and T3 Code

Both take a whole theme file. Zed's is rendered to
`~/.config/zed/themes/ze.json` and `zed/.config/zed/settings.json` selects
`"Ze"`, so Zed recolours on the spot. T3 Code's goes to
`~/.t3/userdata/themes/ze.json`. Pick "ze" once in its appearance settings and
it follows from then on.

### hyprlock and hypridle

`hyprlock/.config/hypr/hyprlock.conf` sources the rendered `hyprlock.conf`:
the desktop wallpaper blurred, the time and date, and a password field in the
theme's colours. hypridle locks after 5 minutes, turns the screen off at 10,
suspends at 30, and locks before sleep. `SUPER + L` locks now.

### SDDM

The greeter is a small Qt6 theme at `/usr/share/sddm/themes/ze`. `install.sh`
copies it there once, and makes its `current/` directory owned by you. On a
theme set, `ze` renders `sddm.conf.tpl` into `current/theme.conf` and copies
the login wallpaper to `current/background.<ext>`. If a file with the same
name and an `.mp4` extension sits next to the wallpaper, it is copied too and
the greeter plays it as a video. None of this needs sudo.

Webp wallpapers need `qt6-imageformats`, which is in the package list.

## Step 4: wallpapers

Two wallpapers are tracked, both as symlinks in `~/.config/ze/current/`:

- `background`, the desktop one, drawn by
  [awww](https://codeberg.org/LGFae/awww) with a one-second fade.
- `login-background`, the login-screen one, copied into the SDDM theme.

A theme set points the desktop at the theme's first wallpaper (sorted by
name, which is why they are numbered `0-`, `1-`, `2-`) and the login screen at
the theme's `login.*` if it has one, else the same wallpaper. From there,
`ze bg next`, `ze bg set` and `ze bg pick` take `--login` or `--both` to move
one or both.

A theme's wallpapers are its `backgrounds/` directory plus anything you put in
`ze/.local/share/ze/backgrounds/<theme>/`. The second place is for wallpapers
you want to keep out of the theme directory, for instance so `ze theme sync`
never touches them.

At login, Hyprland's autostart runs `ze bg restore`, which starts awww and
draws whatever `background` points at.
