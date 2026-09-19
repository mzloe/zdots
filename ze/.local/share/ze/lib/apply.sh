# Push the current theme to every app: reload the ones that include the rendered
# files, and write the ones that need their own copy. Each step is a no-op when
# the app is not installed, so a program installed later is themed on the next
# `ze theme set`.

source "$ZE_SHARE/lib/colors.sh"

ze_apply_all() {
  ze_load_colors "$ZE_CURRENT_THEME_PATH/colors.toml"

  ze_apply_reloads
  ze_apply_btop
  ze_apply_gtk
  ze_apply_flameshot
  ze_apply_browsers
  ze_apply_nvim
  ze_apply_zed
  ze_apply_t3code
  ze_apply_sddm
}

ze_apply_reloads() {
  [[ -n $HYPRLAND_INSTANCE_SIGNATURE ]] && hyprctl reload >/dev/null 2>&1
  pkill -SIGUSR2 -x waybar
  pkill -SIGUSR2 -x ghostty
  # swaync-client blocks forever when there is no daemon to answer
  pgrep -x swaync >/dev/null && timeout 2 swaync-client -rs >/dev/null 2>&1
  return 0
}

# btop only finds themes by name inside its own themes dir
ze_apply_btop() {
  mkdir -p "$HOME/.config/btop/themes"
  ln -nsf "$ZE_CURRENT_THEME_PATH/btop.theme" "$HOME/.config/btop/themes/current.theme"
  pkill -SIGUSR2 -x btop
  return 0
}

# Light/dark mode and the per-theme icon set. gsettings is what Wayland GTK apps
# read; settings.ini is what nwg-look shows and what XWayland GTK apps read.
ze_apply_gtk() {
  local mode gtk_theme prefer_dark icon_theme version

  mode=$(ze_color mode)
  if [[ $mode == light ]]; then
    gtk_theme=Adwaita prefer_dark=0
  else
    gtk_theme=Adwaita-dark prefer_dark=1
  fi

  # A Yaru variant the package doesn't ship (e.g. Yaru-gray) falls back to plain Yaru
  icon_theme=$(cat "$ZE_CURRENT_THEME_PATH/icons.theme" 2>/dev/null || echo Yaru)
  [[ -d /usr/share/icons/$icon_theme ]] || icon_theme=Yaru
  [[ -d /usr/share/icons/$icon_theme ]] || icon_theme=Adwaita

  if [[ -n $DBUS_SESSION_BUS_ADDRESS ]] && command -v gsettings >/dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme "prefer-$mode"
    gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
    gsettings set org.gnome.desktop.interface icon-theme "$icon_theme"
  fi

  for version in gtk-3.0 gtk-4.0; do
    ze_set_ini_key "$HOME/.config/$version/settings.ini" gtk-theme-name "$gtk_theme"
    ze_set_ini_key "$HOME/.config/$version/settings.ini" gtk-icon-theme-name "$icon_theme"
    ze_set_ini_key "$HOME/.config/$version/settings.ini" gtk-application-prefer-dark-theme "$prefer_dark"
  done
}

# Replace `key=value` under [Settings], appending the key (and file) when missing
ze_set_ini_key() {
  local file="$1" key="$2" value="$3"

  mkdir -p "$(dirname "$file")"
  [[ -f $file ]] || printf '[Settings]\n' >"$file"

  if grep -q "^$key=" "$file"; then
    sed -i "s|^$key=.*|$key=$value|" "$file"
  else
    printf '%s=%s\n' "$key" "$value" >>"$file"
  fi
}

# Flameshot keeps its colours in its own ini and has a config subcommand to set
# them, so no template: the capture toolbar takes the accent, its contrast
# colour the background. Running instances watch the ini and repaint.
ze_apply_flameshot() {
  command -v flameshot >/dev/null || return 0
  [[ -n $WAYLAND_DISPLAY || -n $DISPLAY ]] || return 0

  timeout 5 flameshot config --maincolor "$(ze_color accent)" --contrastcolor "$(ze_color background)" >/dev/null 2>&1
  return 0
}

# Chromium-family frame colour through a machine policy, so every profile of
# every installed browser matches. The only root write in ze; install.sh puts
# the helper in /usr/local/bin and a sudoers rule that allows exactly this call.
ze_apply_browsers() {
  local helper=/usr/local/bin/ze-browser-policy
  local color r g b

  [[ -x $helper ]] || return 0

  # Omarchy's chromium.theme ("r,g,b") wins over the theme background
  if [[ -f $ZE_CURRENT_THEME_PATH/chromium.theme ]]; then
    IFS=', ' read -r r g b <"$ZE_CURRENT_THEME_PATH/chromium.theme"
    color=$(printf '%02x%02x%02x' "$r" "$g" "$b" 2>/dev/null)
  else
    color=$(ze_color background)
    color=${color#\#}
  fi
  color=${color,,}
  [[ $color =~ ^[0-9a-f]{6}$ ]] || return 0

  sudo -n "$helper" "$color" || { echo "ze: browser policy not applied (sudoers rule missing? re-run ze install)" >&2; return 0; }

  ze_refresh_browser chromium chromium
  ze_refresh_browser chrome google-chrome-stable
  ze_refresh_browser brave brave
  ze_refresh_browser brave brave-origin
}

ze_refresh_browser() {
  local process="$1" command="$2"

  if command -v "$command" >/dev/null && pgrep -x "$process" >/dev/null; then
    "$command" --refresh-platform-policy --no-startup-window >/dev/null 2>&1 &
    disown
  fi
}

# Omarchy ships each theme's neovim.lua as a LazyVim spec. Pull the plugin repo
# and colorscheme name out of it into a plain table that nvim/init.lua loads
# with vim.pack, so no distro is needed.
# Themes without a neovim.lua fall back to Neovim's built-in `default` scheme in
# the theme's light/dark mode. To give one a real colorscheme later, drop a
# neovim.lua in the theme dir in omarchy's format:
#   return { { "author/plugin.nvim" }, { "LazyVim/LazyVim", opts = { colorscheme = "name" } } }
ze_apply_nvim() {
  local spec="$ZE_CURRENT_THEME_PATH/neovim.lua"
  local repo="" colorscheme="default"

  if [[ -f $spec ]]; then
    repo=$(grep -oE '"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+"' "$spec" | grep -v 'LazyVim/LazyVim' | head -n 1 | tr -d '"')
    colorscheme=$(grep -oE 'colorscheme *= *"[^"]+"' "$spec" | head -n 1 | sed 's/.*"\(.*\)"/\1/')
    [[ -n $colorscheme ]] || colorscheme=default
  fi

  {
    printf -- '-- generated by ze theme set for %s\n' "$(ze_current_theme_name)"
    printf 'return {\n'
    [[ -n $repo ]] && printf '\trepo = "https://github.com/%s",\n' "$repo"
    printf '\tcolorscheme = "%s",\n\tbackground = "%s",\n}\n' "$colorscheme" "$(ze_color mode)"
  } >"$ZE_CURRENT_THEME_PATH/nvim.lua"

  # Running instances re-read the file on this signal (see nvim/init.lua)
  pkill -SIGUSR1 -x nvim
  return 0
}

# Zed watches ~/.config/zed/themes and hot-reloads; settings.json selects "Ze"
ze_apply_zed() {
  local source="$ZE_CURRENT_THEME_PATH/zed.json"
  local dest="$HOME/.config/zed/themes/ze.json"
  local tmp

  [[ -f $source ]] || return 0
  command -v zed >/dev/null || command -v zeditor >/dev/null || return 0

  mkdir -p "${dest%/*}"
  tmp=$(mktemp "$dest.XXXXXX")
  cp "$source" "$tmp"
  mv "$tmp" "$dest"
  chmod 644 "$dest"
}

# T3 Code watches ~/.t3/userdata/themes and retints on change; the file name is
# the theme id you pick once in its settings.
ze_apply_t3code() {
  local source="$ZE_CURRENT_THEME_PATH/t3code.json"
  local dest="${T3CODE_HOME:-$HOME/.t3}/userdata/themes/ze.json"
  local tmp

  [[ -f $source && -d ${dest%/themes/*} ]] || return 0

  mkdir -p "${dest%/*}"
  tmp=$(mktemp "$dest.XXXXXX")
  cp "$source" "$tmp"
  mv "$tmp" "$dest"
  chmod 644 "$dest"
}

# The greeter runs as the sddm user and cannot read $HOME, so install.sh makes
# /usr/share/sddm/themes/ze/current/ owned by you; the rendered conf and a copy
# of the login wallpaper go there. A sibling <name>.mp4 of the wallpaper plays
# as video (the desktop shows the still, awww has no video).
ZE_SDDM_CURRENT_PATH="${ZE_SDDM_CURRENT_PATH:-/usr/share/sddm/themes/ze/current}"

ze_apply_sddm() {
  local conf="$ZE_CURRENT_THEME_PATH/sddm.conf"
  local background video ext tmp

  [[ -f $conf && -d $ZE_SDDM_CURRENT_PATH && -w $ZE_SDDM_CURRENT_PATH ]] || return 0

  background=$(readlink -f "$ZE_CURRENT_PATH/login-background" 2>/dev/null)
  [[ -f $background ]] || background=$(readlink -f "$ZE_CURRENT_BACKGROUND_LINK" 2>/dev/null)

  rm -f "$ZE_SDDM_CURRENT_PATH"/background.* "$ZE_SDDM_CURRENT_PATH"/video.*
  tmp=$(mktemp "$ZE_SDDM_CURRENT_PATH/theme.conf.XXXXXX")
  cp "$conf" "$tmp"

  if [[ -f $background ]]; then
    ext=${background##*.}
    ext=${ext,,}
    cp "$background" "$ZE_SDDM_CURRENT_PATH/background.$ext"
    printf 'Background="current/background.%s"\n' "$ext" >>"$tmp"

    video="${background%.*}.mp4"
    if [[ -f $video ]]; then
      cp "$video" "$ZE_SDDM_CURRENT_PATH/video.mp4"
      printf 'BackgroundVideo="current/video.mp4"\n' >>"$tmp"
    fi
  fi

  mv "$tmp" "$ZE_SDDM_CURRENT_PATH/theme.conf"
  chmod 644 "$ZE_SDDM_CURRENT_PATH"/*
}
