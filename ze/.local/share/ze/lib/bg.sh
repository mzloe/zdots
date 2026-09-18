# ze bg set | next | pick | restore
#
# Two wallpapers are tracked: the desktop one (drawn by awww, current/background)
# and the login screen one (copied for SDDM, current/login-background).
#   ze bg set <image> [--login | --both]     default: desktop
#   ze bg next [--login | --both]
#   ze bg pick                               asks Desktop / Login screen / Both after choosing

source "$ZE_SHARE/lib/apply.sh"

ZE_LOGIN_BACKGROUND_LINK="$ZE_CURRENT_PATH/login-background"

# Parse [--login | --both] out of "$@"; leaves the rest in ZE_BG_ARGS
ze_bg_target() {
  local arg
  ZE_BG_TARGET=desktop
  ZE_BG_ARGS=()
  for arg in "$@"; do
    case "$arg" in
      --login) ZE_BG_TARGET=login ;;
      --both) ZE_BG_TARGET=both ;;
      --desktop) ZE_BG_TARGET=desktop ;;
      *) ZE_BG_ARGS+=("$arg") ;;
    esac
  done
}

ze_bg_set() {
  local background

  ze_bg_target "$@"
  [[ -n ${ZE_BG_ARGS[0]:-} ]] || ze_die "usage: ze bg set <image> [--login | --both]"
  background=$(realpath "${ZE_BG_ARGS[0]}")
  [[ -f $background ]] || ze_die "file does not exist: $background"

  mkdir -p "$ZE_CURRENT_PATH"

  if [[ $ZE_BG_TARGET != login ]]; then
    ln -nsf "$background" "$ZE_CURRENT_BACKGROUND_LINK"
    ze_bg_draw "$background"
  fi

  if [[ $ZE_BG_TARGET != desktop ]]; then
    ln -nsf "$background" "$ZE_LOGIN_BACKGROUND_LINK"
    ze_apply_sddm
  fi
}

ze_bg_draw() {
  # Nothing to draw on outside a Wayland session (e.g. during install)
  [[ -n $WAYLAND_DISPLAY ]] || return 0

  if ! awww query >/dev/null 2>&1; then
    awww-daemon >/dev/null 2>&1 &
    disown
    for _ in {1..50}; do
      awww query >/dev/null 2>&1 && break
      sleep 0.1
    done
  fi

  awww img "$1" --transition-type fade --transition-duration 1 --transition-fps 60
}

ze_bg_next() {
  local backgrounds current link index i

  ze_bg_target "$@"
  link="$ZE_CURRENT_BACKGROUND_LINK"
  [[ $ZE_BG_TARGET == login ]] && link="$ZE_LOGIN_BACKGROUND_LINK"

  mapfile -d '' -t backgrounds < <(ze_list_backgrounds)

  if (( ${#backgrounds[@]} == 0 )); then
    ze_notify "No background was found for theme"
    return 0
  fi

  current=$(readlink "$link" 2>/dev/null)

  index=-1
  for i in "${!backgrounds[@]}"; do
    if [[ ${backgrounds[$i]} == "$current" ]]; then
      index=$i
      break
    fi
  done

  # No match (or no link yet) lands on the first one
  ze_bg_set "${backgrounds[$(((index + 1) % ${#backgrounds[@]}))]}" "--$ZE_BG_TARGET"
}

# Run at login: start awww and put the remembered wallpaper back
ze_bg_restore() {
  if [[ -f $ZE_CURRENT_BACKGROUND_LINK ]]; then
    ze_bg_set "$(readlink -f "$ZE_CURRENT_BACKGROUND_LINK")"
  else
    ze_bg_next
  fi
}

ze_bg_pick() {
  local selection target

  source "$ZE_SHARE/lib/picker.sh"

  selection=$(ze_pick_image "$@" \
    --selected "$(readlink "$ZE_CURRENT_BACKGROUND_LINK" 2>/dev/null)" \
    "$ZE_BACKGROUNDS_PATH/$(ze_current_theme_name)" \
    "$ZE_CURRENT_THEME_PATH/backgrounds")
  [[ -n $selection ]] || return 0

  if command -v rofi >/dev/null; then
    # A three-item menu: no search bar or mode tabs, just the question and the choices
    target=$(printf 'Desktop\nLogin screen\nBoth\n' | rofi -dmenu -i -mesg "Apply wallpaper to" \
      -theme-str 'mainbox { children: [ "message", "listview" ]; } listview { lines: 3; fixed-height: false; } window { width: 320px; }')
    case "$target" in
      Desktop) target=desktop ;;
      "Login screen") target=login ;;
      Both) target=both ;;
      *) return 0 ;;
    esac
  else
    target=both
  fi

  ze_bg_set "$selection" "--$target"
}
