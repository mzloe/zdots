# Install

```sh
git clone https://github.com/mzloe/zdots.git ~/workspace/personal/zdots
cd ~/workspace/personal/zdots && ./install.sh
```

Then log out and back in. That is the whole install. The rest of this page is
what happens while you wait, and how to re-run one piece later.

You need a fresh Arch install, a network connection, and a user that can run
sudo. Budget 20 minutes. Pacman takes most of it. The AUR builds take the
rest and will stop to show you each PKGBUILD, so stay near the keyboard.

## The three steps, spelled out

1. Clone the repo. It has to stay where you clone it, because every config is
   a symlink back into it. Move it later and every app forgets its settings.

   ```sh
   git clone https://github.com/mzloe/zdots.git ~/workspace/personal/zdots
   cd ~/workspace/personal/zdots
   ```

2. Run the installer. Pass a theme name to start with something other than
   gruvbox-light.

   ```sh
   ./install.sh
   ./install.sh tokyo-night
   ```

3. Log out and back in. SDDM shows the `ze` greeter and Hyprland starts with
   the theme already applied.

## What the installer does, in order

1. Installs the 95 pacman packages in `packages/pacman.txt`. Unattended,
   because pacman packages are signed.
2. Builds yay the way yay's README says to, then installs the 6 packages in
   `packages/aur.txt`. Each PKGBUILD is shown first, because AUR builds are
   not signed and you are the review.
3. Enables sddm, NetworkManager and bluetooth.
4. Links every config into `$HOME` with GNU stow. Anything already in the way
   is renamed to `<name>.bak.<timestamp>`. Nothing is deleted.
5. Installs the SDDM greeter and the two sudo helpers, then applies the theme.

## Running one part again

`ze install` is the same script. Run it whole or in part, as often as you
like.

| Command | Does | Takes |
| --- | --- | --- |
| `ze install` | everything above | 20 minutes |
| `ze install --no-packages` | everything but pacman and the AUR | 1 minute |
| `ze install --stow` | only relinks the configs into `$HOME` | 5 seconds |
| `ze install --system` | only the greeter and the sudo helpers, then re-applies the theme | 10 seconds, one sudo prompt |
| `ze install <theme>` | the full run, starting from that theme | 20 minutes |

When to reach for which:

- You added a file to `hypr/`, `rofi/` or another stowed directory and the
  app cannot see it: `ze install --stow`.
- You changed a sudo helper, a sudoers file, or the greeter's QML:
  `ze install --system`.
- New machine: the full run.

## The package lists

`packages/pacman.txt` is grouped by purpose, with a comment above each group.
`packages/aur.txt` is six lines. Two things to know:

- The hardware group is an Intel laptop. Swap `intel-ucode` and
  `vulkan-intel` for your CPU and GPU before the first run.
- A line that starts with `-` is refused, so nothing in the lists can turn
  into a pacman option by accident.

## What runs as root

Two helpers, each with a sudoers rule that spells out its only allowed
arguments, and the SDDM greeter files. The details, and what each one will
and will not accept, are in
[theming.md, trust boundaries](theming.md#trust-boundaries).
