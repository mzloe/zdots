#!/usr/bin/env bash
# Clipboard history picker: a rofi script mode over cliphist.
#
#   clipboard.sh toggle    open the picker, or close it if it is already open
#   clipboard.sh confirm   ask before wiping the history (used by the picker)
#
# rofi re-runs this script itself: once to list the history and again for every
# action, with the chosen row in $1, its id in ROFI_INFO and the key that was
# pressed in ROFI_RETV. Printing rows keeps the menu open, printing nothing
# closes it. Layout lives in ../clipboard.rasi.
#
#   Enter         paste into the window under the picker
#   Shift+Enter   copy only
#   Ctrl+Enter    open an image entry in imv
#   Delete        remove the highlighted entry
#   Shift+Delete  clear the whole history, after a confirmation
#                 (the "Clear history" button at the bottom does the same)

set -o pipefail

self=$(readlink -f "$0")
theme=$(readlink -f "$(dirname "$self")/../clipboard.rasi")
thumbs="${XDG_RUNTIME_DIR:-/tmp}/cliphist-thumbs"
terminal_class="com.mitchellh.ghostty"

toggle() {
  # Same keybind again closes an open picker. The pattern matches only the rofi
  # started here, so the app launcher is left alone.
  if pkill -f "rofi .*clipboard.rasi"; then
    exit 0
  fi
  exec rofi -show clipboard -modi "clipboard:$self" -theme "$theme" -show-icons \
    -kb-accept-alt "" -kb-accept-custom "" -kb-delete-entry "" \
    -kb-remove-char-forward "Control+d" \
    -kb-custom-1 "Shift+Return" \
    -kb-custom-2 "Control+Return" \
    -kb-custom-3 "Delete" \
    -kb-custom-4 "Shift+Delete"
}

# Same small prompt as the wallpaper picker's Desktop / Login screen question.
confirm() {
  local answer
  answer=$(printf 'No\nYes\n' | rofi -dmenu -i \
    -mesg "Delete the entire clipboard history?" \
    -theme-str 'mainbox { children: [ "message", "listview" ]; } listview { lines: 2; fixed-height: false; } window { width: 360px; }')
  [[ $answer == "Yes" ]] && wipe
}

# Print a row. Extra rofi options follow the text after a NUL, as key/value
# pairs separated by the unit separator.
row() { # row <text> <key> <value> [<key> <value>...]
  local text=$1
  shift
  printf '%s\0' "$text"
  local sep=""
  while (($# > 1)); do
    printf '%s%s\x1f%s' "$sep" "$1" "$2"
    sep=$'\x1f'
    shift 2
  done
  printf '\n'
}

option() { printf '\0%s\x1f%s\n' "$1" "$2"; }

# cliphist takes an id from the text before a tab; a trailing newline is an error.
entry() { printf '%s\t' "$1"; }

# Image entries preview as "[[ binary data 12 KiB png 640x480 ]]".
image_parts() { # image_parts <preview>  -> sets ext, size, dims
  [[ $1 =~ ^\[\[\ binary\ data\ ([0-9]+\ [A-Za-z]+)\ (png|jpe?g|gif|bmp|webp)\ ([0-9]+x[0-9]+) ]] || return 1
  size=${BASH_REMATCH[1]}
  ext=${BASH_REMATCH[2]}
  dims=${BASH_REMATCH[3]}
}

thumb() { # thumb <id> <preview>  -> path of a decoded copy, if it is an image
  local ext size dims file
  image_parts "$2" || return 1
  file="$thumbs/$1.$ext"
  if [[ ! -s $file ]]; then
    mkdir -p "$thumbs"
    entry "$1" | cliphist decode >"$file" || return 1
  fi
  printf '%s' "$file"
}

label() { # label <preview>  -> what the row shows
  local ext size dims
  if image_parts "$1"; then
    printf 'Image %s %s (%s)' "$ext" "$dims" "$size"
  else
    printf '%s' "$1"
  fi
}

list() {
  local entries id preview file
  entries=$(cliphist list)
  if [[ -z $entries ]]; then
    # rofi quits at once when a script prints no rows, so show one placeholder.
    row "History is empty" info empty
    return
  fi
  option use-hot-keys true
  option no-custom true
  while IFS=$'\t' read -r id preview; do
    [[ $preview == "<meta http-equiv="* ]] && continue
    if file=$(thumb "$id" "$preview"); then
      row "$(label "$preview")" info "$id" icon "$file"
    else
      row "$preview" info "$id"
    fi
  done <<<"$entries"
}

copy() { entry "$1" | cliphist decode | wl-copy; }

# Runs after rofi has closed and focus is back on the previous window.
paste_later() {
  local class keys
  class=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty')
  if [[ $class == "$terminal_class" ]]; then
    keys=(-M shift -k Insert -m shift)
  else
    keys=(-M ctrl -k v -m ctrl)
  fi
  setsid -f bash -c 'sleep 0.15; wtype "$@"' _ "${keys[@]}" >/dev/null 2>&1
}

open_image() { # open_image <id> <preview>
  local file
  file=$(thumb "$1" "$2") || return 1
  setsid -f imv "$file" >/dev/null 2>&1
}

remove() { # remove <id>
  entry "$1" | cliphist delete
  rm -f "$thumbs/$1".*
}

wipe() {
  cliphist wipe
  rm -rf "$thumbs"
}

# The picker must close before another rofi can open, so the prompt is detached
# and waits for it.
confirm_later() {
  setsid -f bash -c 'while pgrep -x rofi >/dev/null; do sleep 0.05; done; "$0" confirm' "$self" >/dev/null 2>&1
}

is_entry() { [[ ${1:-} =~ ^[0-9]+$ ]]; }

case "${1:-}" in
  toggle) toggle ;;
  confirm) confirm; exit ;;
esac

id=${ROFI_INFO:-}
preview=${1:-}

case "${ROFI_RETV:-0}" in
  0) list ;;
  1) is_entry "$id" && { copy "$id"; paste_later; } ;;
  10) if is_entry "$id"; then copy "$id"; else list; fi ;;
  11) if is_entry "$id" && open_image "$id" "$preview"; then :; else list; fi ;;
  12) is_entry "$id" && remove "$id"; list ;;
  13) if [[ -n $(cliphist list) ]]; then confirm_later; else list; fi ;;
  *) list ;;
esac
