# Make it yours

Three things you will want to do sooner or later: add a theme, theme an app
that is not covered yet, and pull in whatever omarchy added since. Each one is
short.

## Add a theme

A theme is a directory in `ze/.local/share/ze/themes/`. Two files are
required, the rest is optional.

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

1. Create the directory and copy a `colors.toml` from a theme that is close to
   what you want. Any of the 21 works as a starting point.
2. Change the colours. `mode` is `"dark"` or `"light"`. `accent`,
   `background` and `foreground` do most of the work. Everything else can be
   left out and `ze` derives it, but a theme looks better when you set the
   `dark_`, `darker_` and `lighter_` backgrounds yourself.
3. Put at least one image in `backgrounds/`. Name them `0-`, `1-`, `2-` to
   control the order. jpg, jpeg, png, gif, bmp and webp all work.
4. Run `ze theme set my-theme`.

Details worth knowing:

- `login.*` may be a symlink into `backgrounds/`. When it exists, a theme set
  puts it on the login screen and the first background on the desktop.
- An `.mp4` next to a wallpaper, with the same base name, plays as video on
  the login screen. The desktop shows the still.
- `preview.png` is what `ze theme pick` shows. Without one the picker falls
  back to the theme's first background. The 21 shipped previews are 1800 by
  1012 renders of the real desktop.
- `neovim.lua` is a LazyVim plugin spec. Copy one from another theme and change
  the repo and the colorscheme name:

  ```lua
  return {
    { "folke/tokyonight.nvim", priority = 1000 },
    { "LazyVim/LazyVim", opts = { colorscheme = "tokyonight-night" } },
  }
  ```

- Wallpapers you want to keep out of the theme directory go in
  `ze/.local/share/ze/backgrounds/<theme>/`. `ze bg pick` and `ze bg next` see
  both places.

## Theme another app

`ze` themes an app by rendering a template into
`~/.config/ze/current/theme/` and having the app include that file. Adding an
app is three steps.

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
   signal (`pkill -SIGUSR2 -x <app>`) or have a client command. Guard it so it
   does nothing when the app is not installed.

Run `ze theme set "$(ze theme current)"` to render and check the result.

## Pull omarchy's new themes

```sh
ze theme sync
git diff --stat
git add -A ze/.local/share/ze/themes && git commit -m "Sync themes from omarchy"
```

Sync clones omarchy's `themes/` directory into `~/.cache/ze/omarchy` (a shallow
clone, only that directory) and copies every theme over. It adds and updates.
It never deletes, so your own themes, your extra wallpapers and any edits you
made to an omarchy theme's files stay put, unless omarchy changed that same
file, in which case the diff shows it and you decide.

What sync leaves out:

- Themes named in `themes/.sync-ignore`. Right now that is hackerman,
  flexoki-light, lumon and white, the ones merged into other themes or dropped
  on purpose. Add a name there to stop a theme from coming back.
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
- `lumon` is gone. `post-apocalyptic-hacker` is new.
- `everforest` and `nord` are unchanged and kept separate.

The added wallpapers come from sddm-astronaut-theme.
