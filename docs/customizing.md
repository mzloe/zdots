# Make it yours

Four things you will want sooner or later, each one short:

1. [Add a wallpaper to a theme](#add-a-wallpaper-to-a-theme). One copy. 1 minute.
2. [Add a theme](#add-a-theme). One `colors.toml`, one folder of images. 15 minutes.
3. [Theme another app](#theme-another-app). One template, one include line. 10 minutes.
4. [Pull omarchy's new themes](#pull-omarchys-new-themes). One command, then read the diff. 5 minutes.

## Add a wallpaper to a theme

A theme's wallpapers come from two folders. `ze bg pick`, `ze bg next` and
the theme set see both:

| Folder | Read from | Shows in the picker |
| --- | --- | --- |
| `ze/.local/share/ze/backgrounds/<theme>/` | the repo, live | at once |
| `ze/.local/share/ze/themes/<theme>/backgrounds/` | the copy made by the last theme set | after `ze theme set <theme>` |

Use the first for wallpapers that are yours. Use the second for wallpapers
that belong to the theme and should ship with it. jpg, jpeg, png, gif, bmp
and webp all work. `ze` reads the repo directly, so no restow is needed.

### Option A: your own wallpaper, visible at once

1. Copy the image in. Create the folder if the theme has none yet.

   ```sh
   mkdir -p ze/.local/share/ze/backgrounds/tokyo-night
   cp ~/Pictures/sunset.jpg ze/.local/share/ze/backgrounds/tokyo-night/sunset.jpg
   ```

2. Press `ALT + SHIFT + W`. The new image is in the carousel.

### Option B: part of the theme

1. Copy the image into the theme. Give it a number prefix. Wallpapers sort by
   name and the first one is what a theme set puts on the desktop.

   ```sh
   cp ~/Pictures/sunset.jpg ze/.local/share/ze/themes/tokyo-night/backgrounds/4-sunset.jpg
   ```

2. Re-apply the theme so the picker's copy is refreshed. This resets the
   desktop to the theme's first wallpaper, so pick the new one afterwards.

   ```sh
   ze theme set tokyo-night
   ```

Extras for either option:

- An `.mp4` with the same base name next to the image plays as video on the
  login screen. The desktop shows the still.
- To make it the theme's default login wallpaper, point `login.*` at it:
  `ln -sf backgrounds/4-sunset.jpg ze/.local/share/ze/themes/tokyo-night/login.jpg`.
- The carousel caches thumbnails by file size and modification time, so a
  replaced image is re-thumbnailed the next time it opens.

## Add a theme

A theme is a directory in `ze/.local/share/ze/themes/`. Two files are
required. The rest is optional.

```
themes/my-theme/
  colors.toml        required. The palette, see below
  backgrounds/       required. At least one image
  login.png          optional. Default login-screen wallpaper
  preview.png        optional. What the theme picker shows
  neovim.lua         optional. Neovim colorscheme, omarchy's format
  icons.theme        optional. A Yaru variant, e.g. Yaru-magenta
  chromium.theme     optional. "r,g,b" for the browser frame
  btop.theme, ghostty.conf, ...   optional. Hand-written files that replace the template output
```

Four of those are code, not colours. Hyprland runs `hyprland.lua`, hyprlock
and ghostty run commands named in `hyprlock.conf` and `ghostty.conf`, and
Neovim clones the repo named in `neovim.lua`. Read them before you drop a
theme someone sent you into this directory.

1. Create the directory and copy a `colors.toml` from a theme that is close
   to what you want. Any of the 21 is a fine start.
2. Change the colours. `mode` is `"dark"` or `"light"`. `accent`,
   `background` and `foreground` do most of the work. Everything else can be
   left out and `ze` derives it, but a theme looks better when you set the
   `dark_`, `darker_` and `lighter_` backgrounds yourself.
3. Put at least one image in `backgrounds/`. Name them `0-`, `1-`, `2-` to
   control the order.
4. Run `ze theme set my-theme`.

Details worth knowing:

- `login.*` may be a symlink into `backgrounds/`. When it exists, a theme
  set puts it on the login screen and the first background on the desktop.
- `preview.png` is what `ze theme pick` shows. Without one the picker falls
  back to the theme's first background. The 21 shipped previews are 1799 by
  1012 renders of the real desktop. Yes, 1799. No, I do not know either.
- `neovim.lua` is a LazyVim plugin spec. Copy one from another theme and
  change the repo and the colorscheme name:

  ```lua
  return {
    { "folke/tokyonight.nvim", priority = 1000 },
    { "LazyVim/LazyVim", opts = { colorscheme = "tokyonight-night" } },
  }
  ```

## Theme another app

`ze` themes an app by rendering a template into `~/.config/ze/current/theme/`
and having the app include that file. Three steps.

1. Write `ze/.local/share/ze/templates/<name>.tpl`. The rendered file keeps
   the name without `.tpl`. Use the placeholders from the table in
   [theming.md](theming.md#step-2-colours-and-templates). To see every key
   you can use and its value in the current theme:

   ```sh
   ze theme color --all
   ```

   A minimal example, for an app that reads a CSS file:

   ```css
   @define-color bg {{ background }};
   @define-color fg {{ foreground }};
   @define-color accent {{ accent }};
   @define-color accent-dim {{ mix background accent 30% }};
   ```

2. Make the app's config include `~/.config/ze/current/theme/<name>`. How
   depends on the app: `@import` for CSS, `config-file` for ghostty, `source`
   for hyprlang, a symlink for apps that only look in their own directory
   (that is what btop needed).

3. If the app does not pick up the change by itself, add a reload to
   `ze_apply_reloads` in `ze/.local/share/ze/lib/apply.sh`. Most apps take a
   signal (`pkill -SIGUSR2 -x <app>`) or have a client command. Guard it so
   it does nothing when the app is not installed.

Then run `ze theme set "$(ze theme current)"` and look at the result.

## Pull omarchy's new themes

```sh
ze theme sync
```

Sync clones omarchy's `themes/` directory into `~/.cache/ze/omarchy` (a
shallow clone, only that directory) and copies every theme over. It adds and
updates. It never deletes, so your own themes, your extra wallpapers and any
edits you made to an omarchy theme's files stay put, unless omarchy changed
that same file, in which case the diff shows it and you decide.

Nothing is applied until you commit. Like makepkg showing a PKGBUILD, sync
lists what changed, points out any file that is code rather than colours
(`hyprland.lua`, `hyprlock.conf`, `ghostty.conf`, `neovim.lua`), and offers
the diff. Upstream is pulled straight from omarchy's default branch, so that
read is your review. When it looks right:

```sh
git add -A ze/.local/share/ze/themes && git commit -m "Sync themes from omarchy"
```

What sync leaves out:

- Themes named in `themes/.sync-ignore`. Right now that is hackerman,
  flexoki-light, lumon and white, the ones merged into other themes or
  dropped on purpose. Add a name there to stop a theme from coming back.
- Wallpapers with "omarchy" in the file name.
- `unlock.png` and `preview-unlock.png`, the Omarchy-branded Plymouth images.
- `vscode.json`. VS Code is not themed here.
- `preview.*` when the theme already has a preview, so the rendered previews
  survive.

The upstream commit sync last ran against is written to
`themes/.omarchy-version`.

## Where this set differs from omarchy

- `cyberpunk` is omarchy's hackerman palette with a cyberpunk wallpaper.
- `gruvbox-light` took in flexoki-light's wallpapers and its browser colour.
- `catppuccin-latte` took in white's wallpapers. Its palette is darkened
  from the official latte for contrast on those.
- `catppuccin` gained the black-hole, jake-the-dog and hyprland-kath
  wallpapers (the last two with video) and the astronaut login screen.
- `rose-pine` gained pixel-sakura as png and gif and a login wallpaper.

`lumon` is gone, `post-apocalyptic-hacker` is new, and `everforest` and
`nord` are unchanged. The added wallpapers come from sddm-astronaut-theme.
