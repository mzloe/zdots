# zdots

My Arch + Hyprland desktop, and `ze`, the one command that repaints all of it.

```sh
ze theme set nord
```

Terminal, bar, launcher, notifications, btop, GTK apps, Flameshot, Neovim,
Zed, the browsers, the lock screen, the login screen, the wallpaper. One
command, 21 themes, nothing left in the old colours.

`ze` is pronounced like "the", so the commands read as sentences. "ze theme
set." "ze bg next." That is the whole joke and I am keeping it.

## Install

```sh
git clone https://github.com/mzloe/zdots.git ~/workspace/personal/zdots
cd ~/workspace/personal/zdots && ./install.sh
```

Fresh Arch, a user that can sudo, about 20 minutes. Log out and back in when
it finishes. `./install.sh tokyo-night` starts with a theme other than
gruvbox-light. What the installer does, every flag, and how to re-run one part
of it: [docs/install.md](docs/install.md).

## Every day

| Press | Get |
| --- | --- |
| `ALT + SHIFT + T` | a carousel of theme previews |
| `ALT + SHIFT + W` | a carousel of the theme's wallpapers |
| `SUPER + W` | the next wallpaper |
| `SUPER + V` | clipboard history, text and images |
| `Print` | a screenshot, already open in Flameshot's editor |

From a terminal the same things are `ze theme pick`, `ze bg pick`,
`ze bg next` and `ze theme set <name>`. Every key, every `ze` command, the
carousel and the clipboard picker: [docs/keys.md](docs/keys.md).

## How it works

`ze theme set` copies the theme to `~/.config/ze/current/theme/`, renders one
template per app into it, and tells each app to reload. An app that is not
installed is skipped. Install it next month and the next theme set paints it
too. App by app, with the file each one reads: [docs/theming.md](docs/theming.md).
The two things that run as root, and why they are tiny:
[trust boundaries](docs/theming.md#trust-boundaries).

## Previews

Desktop with rofi, the SDDM greeter, then hyprlock. All three come from one
`ze theme set`, captured in a headless compositor.

| | |
| --- | --- |
| catppuccin ![catppuccin](docs/previews/catppuccin.jpg) | catppuccin-latte ![catppuccin-latte](docs/previews/catppuccin-latte.jpg) |
| cyberpunk ![cyberpunk](docs/previews/cyberpunk.jpg) | gruvbox-light ![gruvbox-light](docs/previews/gruvbox-light.jpg) |
| post-apocalyptic-hacker ![post-apocalyptic-hacker](docs/previews/post-apocalyptic-hacker.jpg) | rose-pine ![rose-pine](docs/previews/rose-pine.jpg) |
| tokyo-night ![tokyo-night](docs/previews/tokyo-night.jpg) | |

## Make it yours

A new wallpaper is a copy into one folder. A new theme is a `colors.toml`
and a `backgrounds/` folder. Theming one more app is one template and one
include line. Pulling omarchy's new themes is `ze theme sync`. All four, step
by step: [docs/customizing.md](docs/customizing.md).

## Credits

- [omarchy](https://github.com/omacom/omarchy) by David Heinemeier Hansson.
  The theme format, the themes, the colour resolver, the template renderer
  and the image carousel started there. MIT licensed.
- [sddm-astronaut-theme](https://github.com/Keyitdev/sddm-astronaut-theme)
  by Keyitdev. The `ze` greeter and its icons are derived from it, and so are
  a handful of wallpapers. GPL-3.0-or-later, same as this repo.

## License

GPL-3.0-or-later, see [LICENSE](LICENSE).
