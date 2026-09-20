#!/bin/bash

# Set up a fresh Arch install from this repo. Safe to re-run (also as `ze install`).
# Usage: ./install.sh [--no-packages] [theme-name]

set -euo pipefail

ZDOTS_PATH=$(dirname "$(readlink -f "$0")")
ZE_SYSTEM_PATH="$ZDOTS_PATH/ze/.local/share/ze/system"
DEFAULT_THEME="gruvbox-light"
THEME=""
INSTALL_PACKAGES=true

PACKAGES=(ze hypr hyprlock hypridle waybar rofi swaync ghostty btop fastfetch gtk nvim zed)

for arg in "$@"; do
  case "$arg" in
    --no-packages) INSTALL_PACKAGES=false ;;
    -h | --help)
      echo "Usage: ./install.sh [--no-packages] [theme-name]"
      exit 0
      ;;
    *) THEME="$arg" ;;
  esac
done

if (( EUID == 0 )); then
  echo "Run as your user, not root (sudo is used where needed)" >&2
  exit 1
fi

step() {
  printf '\n\e[1;34m==>\e[0m \e[1m%s\e[0m\n' "$1"
}

package_list() {
  sed -E 's/#.*//; /^[[:space:]]*$/d' "$1"
}

install_packages() {
  local packages

  step "Installing pacman packages"
  mapfile -t packages < <(package_list "$ZDOTS_PATH/packages/pacman.txt")
  sudo pacman -Syu --needed --noconfirm "${packages[@]}"

  if ! command -v yay >/dev/null; then
    step "Installing yay"
    local build_dir
    build_dir=$(mktemp -d)
    # As in yay's README: clone, build, install. makepkg shows the PKGBUILD first.
    git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$build_dir/yay-bin"
    (cd "$build_dir/yay-bin" && makepkg -si)
    rm -rf "$build_dir"
  fi

  # AUR builds are unsigned, so each PKGBUILD is shown for review, as yay does by default
  step "Installing AUR packages"
  mapfile -t packages < <(package_list "$ZDOTS_PATH/packages/aur.txt")
  yay -S --needed "${packages[@]}"

  step "Enabling services"
  sudo systemctl enable sddm NetworkManager bluetooth
}

# Anything real sitting where a package wants to link gets moved to <name>.bak.<timestamp>
backup_conflicts() {
  local package="$1"
  local source target

  while IFS= read -r -d '' source; do
    target="$HOME/${source#"$ZDOTS_PATH/$package/"}"
    if [[ -e $target && ! -L $target ]]; then
      mv "$target" "$target.bak.$(date +%Y%m%d%H%M%S)"
      echo "  backed up $target"
    fi
  done < <(find "$ZDOTS_PATH/$package" -type f -print0)
}

stow_packages() {
  local package

  step "Stowing packages into $HOME"
  for package in "${PACKAGES[@]}"; do
    backup_conflicts "$package"
  done

  # --no-folding links files, not directories, so apps and ze can write next to
  # the links (btop themes, zed themes, gtk settings.ini) without touching the repo
  stow --dir="$ZDOTS_PATH" --target="$HOME" --restow --no-folding "${PACKAGES[@]}"
  echo "  ${PACKAGES[*]}"
}

# Browser theme colour is a machine policy: root-owned helper + passwordless sudo for it
install_browser_policy() {
  step "Installing browser policy helper (sudo)"
  # A sudoers file with a syntax error locks sudo for everyone, so check it first
  visudo -cf "$ZE_SYSTEM_PATH/ze-browser-policy.sudoers"
  sudo install -m 0755 -o root -g root "$ZE_SYSTEM_PATH/ze-browser-policy" /usr/local/bin/ze-browser-policy
  sudo install -m 0440 -o root -g root "$ZE_SYSTEM_PATH/ze-browser-policy.sudoers" /etc/sudoers.d/ze-browser-policy
  sudo install -d -m 0755 -o root -g root \
    /etc/chromium/policies/managed /etc/opt/chrome/policies/managed /etc/brave/policies/managed
}

# The greeter is copied once (root); current/ stays yours so ze can update the
# colours and login wallpaper without sudo
install_sddm_theme() {
  step "Installing SDDM greeter (sudo)"
  sudo install -d -m 0755 -o root -g root /usr/share/sddm/themes/ze
  # Refresh the greeter files but keep current/ (the rendered theme state)
  sudo find /usr/share/sddm/themes/ze -mindepth 1 -maxdepth 1 ! -name current -exec rm -rf {} +
  sudo cp -r "$ZDOTS_PATH/ze/.local/share/ze/sddm/." /usr/share/sddm/themes/ze/
  sudo install -d -m 0755 -o "$USER" -g "$USER" /usr/share/sddm/themes/ze/current
  # Without a rendered conf yet, the example keeps the greeter usable
  [[ -f /usr/share/sddm/themes/ze/current/theme.conf ]] ||
    cp /usr/share/sddm/themes/ze/current.example.conf /usr/share/sddm/themes/ze/current/theme.conf
  sudo install -d -m 0755 /etc/sddm.conf.d
  printf '[Theme]\nCurrent=ze\n' | sudo tee /etc/sddm.conf.d/ze.conf >/dev/null
}

apply_theme() {
  # Without an explicit theme, a re-run keeps the one already in use
  if [[ -z $THEME && -f $HOME/.config/ze/current/theme.name ]]; then
    THEME=$(<"$HOME/.config/ze/current/theme.name")
  fi
  THEME="${THEME:-$DEFAULT_THEME}"

  step "Applying theme: $THEME"
  "$HOME/.local/bin/ze" theme set "$THEME"
}

[[ $INSTALL_PACKAGES == true ]] && install_packages
command -v stow >/dev/null || { echo "stow is not installed (run without --no-packages)" >&2; exit 1; }
stow_packages
install_browser_policy
install_sddm_theme
apply_theme

step "Done. Log out and back in (or reboot) to start Hyprland with the new setup."
