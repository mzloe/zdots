# ze theme set | list | pick

source "$ZE_SHARE/lib/render.sh"
source "$ZE_SHARE/lib/apply.sh"
source "$ZE_SHARE/lib/bg.sh"

ze_theme_list() {
  find -L "$ZE_THEMES_PATH/" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null |
    sort | sed -E 's/(^|-)([a-z])/\1\u\2/g; s/-/ /g'
}

ze_theme_set() {
  local theme_name login

  [[ -n $1 ]] || ze_die "usage: ze theme set <name>"

  # "Tokyo Night" and "tokyo-night" both work
  theme_name=$(echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

  if [[ -z $theme_name || $theme_name == .* || $theme_name == */* ]]; then
    ze_die "invalid theme name: $1"
  fi
  [[ -d $ZE_THEMES_PATH/$theme_name ]] || ze_die "theme '$theme_name' does not exist (see: ze theme list)"

  # Two switches racing would share the staging dir and the current symlinks
  mkdir -p "$ZE_CURRENT_PATH"
  exec 9>"$(ze_runtime_dir)/ze-theme-set.lock"
  flock 9

  # Stage in next-theme so apps never read a half-written theme
  rm -rf "$ZE_NEXT_THEME_PATH"
  mkdir -p "$ZE_NEXT_THEME_PATH"
  cp -r "$ZE_THEMES_PATH/$theme_name/"* "$ZE_NEXT_THEME_PATH/"
  ze_render_templates "$ZE_NEXT_THEME_PATH"

  rm -rf "$ZE_CURRENT_THEME_PATH"
  mv "$ZE_NEXT_THEME_PATH" "$ZE_CURRENT_THEME_PATH"
  echo "$theme_name" >"$ZE_CURRENT_THEME_NAME_FILE"

  flock -u 9

  ze_apply_all

  # The old wallpapers belong to the old theme: desktop gets the theme's first
  # background, the login screen its login.* if it ships one, else the same.
  rm -f "$ZE_CURRENT_BACKGROUND_LINK" "$ZE_LOGIN_BACKGROUND_LINK"
  ze_bg_next --both
  login=$(find -L "$ZE_CURRENT_THEME_PATH" -maxdepth 1 -type f -iname 'login.*' -print -quit)
  [[ -n $login ]] && ze_bg_set "$login" --login

  # Warm the wallpaper picker thumbnails for the new theme
  ze_bg_pick --cache-only >/dev/null 2>&1 &
}

ze_theme_pick() {
  local preview_dir="$ZE_CACHE_PATH/theme-previews"
  local theme_path theme_name preview selected theme

  source "$ZE_SHARE/lib/picker.sh"

  find_preview() {
    local preview

    preview=$(find -L "$1" -maxdepth 1 -type f -iname 'preview.*' ! -iname 'preview-*' -print -quit 2>/dev/null)

    # No preview shipped: the theme's first wallpaper stands in
    if [[ -z $preview ]]; then
      preview=$(find -L "$1/backgrounds" "${ZE_IMAGE_FIND_ARGS[@]}" -print 2>/dev/null | sort | head -n 1)
    fi

    printf '%s' "$preview"
  }

  # The carousel labels slices by file name, so link every preview as <theme>.<ext>
  rm -rf "$preview_dir"
  mkdir -p "$preview_dir"

  while IFS= read -r theme_path; do
    theme_name=${theme_path##*/}
    preview=$(find_preview "$theme_path")
    [[ -n $preview ]] && ln -s "$preview" "$preview_dir/$theme_name.${preview##*.}"
  done < <(find -L "$ZE_THEMES_PATH/" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

  selected=$(compgen -G "$preview_dir/$(ze_current_theme_name).*" | head -n 1)

  theme=$(ze_pick_image "$@" --print-name --show-labels --filterable --selected "$selected" "$preview_dir")
  [[ -n $theme ]] && ze_theme_set "$theme"
}
