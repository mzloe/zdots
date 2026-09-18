# The image carousel (picker/shell.qml, run with quickshell).
#
#   ze_pick_image [--selected <image>] [--print-name] [--show-labels] [--filterable] [--cache-only] <dir>...
#
# Prints the chosen path (or its bare name with --print-name), nothing on cancel.

source "$ZE_SHARE/lib/colors.sh"

ze_pick_image() {
  local selected_image="" print_name=false show_labels=false filterable=false cache_only=false
  local image_dirs=()
  local cache_dir rows_file pending_file selection_file image signature hash thumbnail selection

  while (( $# > 0 )); do
    case "$1" in
      --selected) selected_image="$2"; shift 2 ;;
      --print-name) print_name=true; shift ;;
      --show-labels) show_labels=true; shift ;;
      --filterable) filterable=true; shift ;;
      --cache-only) cache_only=true; shift ;;
      *) image_dirs+=("$1"); shift ;;
    esac
  done

  (( ${#image_dirs[@]} > 0 )) || ze_die "ze_pick_image: no image directory given"

  # Same keybind again closes an open picker instead of stacking a second one
  if [[ $cache_only != true ]] && pkill -f "quickshell -p $ZE_PICKER_PATH"; then
    return 0
  fi

  cache_dir="$ZE_CACHE_PATH/image-selector"
  mkdir -p "$cache_dir"

  rows_file=$(mktemp)
  pending_file=$(mktemp)
  selection_file=$(mktemp)
  trap 'rm -f "$rows_file" "$pending_file" "$selection_file"' RETURN

  # Full-size wallpapers are slow to decode, so the carousel draws cached thumbnails
  while IFS= read -r -d '' image; do
    signature=$(stat -Lc '%s:%Y' "$image") || continue
    hash=$(printf '%s\t%s' "$image" "$signature" | md5sum | cut -d ' ' -f 1)
    thumbnail="$cache_dir/$hash.jpg"

    [[ -f $thumbnail ]] || printf '%s\0%s\0' "$image" "$thumbnail" >>"$pending_file"
    printf '%s\t%s\n' "$image" "$thumbnail" >>"$rows_file"
  done < <(find -L "${image_dirs[@]}" "${ZE_IMAGE_FIND_ARGS[@]}" -print0 2>/dev/null | sort -z)

  if [[ -s $pending_file ]]; then
    # Write to a temp name first so a killed run never leaves a half-written thumbnail
    xargs -a "$pending_file" -0 -n 2 -P "$(nproc)" bash -c \
      'VIPS_CONCURRENCY=1 vipsthumbnail "$1" --size 1536x864 --smartcrop=centre --path "$2.$$.jpg[Q=82,strip]" && mv -f "$2.$$.jpg" "$2"' _ >/dev/null 2>&1
  fi

  [[ $cache_only == true ]] && return 0

  if [[ ! -s $rows_file ]]; then
    ze_notify "No images found"
    return 1
  fi

  ze_load_colors "$ZE_CURRENT_THEME_PATH/colors.toml" 2>/dev/null

  ZE_PICKER_ROWS_FILE="$rows_file" \
  ZE_PICKER_SELECTION_FILE="$selection_file" \
  ZE_PICKER_SELECTED="$selected_image" \
  ZE_PICKER_SHOW_LABELS="$show_labels" \
  ZE_PICKER_FILTERABLE="$filterable" \
  ZE_PICKER_BACKGROUND=$(ze_color background "#1e1e2e") \
  ZE_PICKER_FOREGROUND=$(ze_color foreground "#cdd6f4") \
  ZE_PICKER_ACCENT=$(ze_color accent "#89b4fa") \
    quickshell -p "$ZE_PICKER_PATH" >/dev/null 2>&1

  if [[ -s $selection_file ]]; then
    selection=$(<"$selection_file")
    if [[ $print_name == true ]]; then
      selection=${selection##*/}
      selection=${selection%.*}
    fi
    printf '%s\n' "$selection"
  fi
}
