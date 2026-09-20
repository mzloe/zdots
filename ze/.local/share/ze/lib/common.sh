# Paths and helpers shared by every ze command. Sourced by bin/ze.

ZE_THEMES_PATH="$ZE_SHARE/themes"
ZE_BACKGROUNDS_PATH="$ZE_SHARE/backgrounds"
ZE_TEMPLATES_PATH="$ZE_SHARE/templates"
ZE_PICKER_PATH="$ZE_SHARE/picker"

# Lives under ~/.config so GTK CSS can reach it with a relative @import
ZE_CURRENT_PATH="$HOME/.config/ze/current"
ZE_CURRENT_THEME_PATH="$ZE_CURRENT_PATH/theme"
ZE_NEXT_THEME_PATH="$ZE_CURRENT_PATH/next-theme"
ZE_CURRENT_THEME_NAME_FILE="$ZE_CURRENT_PATH/theme.name"
ZE_CURRENT_BACKGROUND_LINK="$ZE_CURRENT_PATH/background"

ZE_CACHE_PATH="${XDG_CACHE_HOME:-$HOME/.cache}/ze"

ZE_IMAGE_FIND_ARGS=(-maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.webp' \))

ze_notify() {
  command -v notify-send >/dev/null && notify-send -t 2000 "ze" "$1"
  echo "$1" >&2
}

ze_die() {
  echo "ze: $1" >&2
  exit 1
}

ze_current_theme_name() {
  cat "$ZE_CURRENT_THEME_NAME_FILE" 2>/dev/null
}

# Backgrounds of the current theme: the extras in backgrounds/<theme> first, then the theme's own
ze_list_backgrounds() {
  find -L "$ZE_BACKGROUNDS_PATH/$(ze_current_theme_name)/" "$ZE_CURRENT_THEME_PATH/backgrounds/" \
    "${ZE_IMAGE_FIND_ARGS[@]}" -print0 2>/dev/null | sort -z
}

# Where locks and scratch files go: XDG_RUNTIME_DIR in a session; outside one
# (cron, ssh) a 0700 directory of our own rather than a fixed name in /tmp
ze_runtime_dir() {
  local dir="${XDG_RUNTIME_DIR:-}"
  if [[ -z $dir ]]; then
    dir="${TMPDIR:-/tmp}/ze-$UID"
    mkdir -m 700 -p "$dir"
    [[ -O $dir && ! -L $dir ]] || ze_die "$dir is not ours"
  fi
  printf '%s' "$dir"
}
