# Render templates/*.tpl against a theme's colors.toml.
#
# Placeholders: {{ key }}, {{ key_strip }} (no #), {{ key_rgb }} (r,g,b),
# {{ mix a b 30% }}, {{ hypr_gradient key fallback }}, {{ gradient_start key }}.
#
#   ze_render_templates <theme-dir>   writes one file per template into <theme-dir>,
#                                     never overwriting a file the theme ships itself

source "$ZE_SHARE/lib/colors.sh"

# Convert hex color to decimal RGB (e.g., "#1e1e2e" -> "30,30,46")
hex_to_rgb() {
  local hex="${1#\#}"
  printf "%d,%d,%d" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

trim() {
  local value="$1"

  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf "%s" "$value"
}

resolve_theme_ref() {
  local ref="$1"
  local fallback="${2:-}"

  if [[ -n ${THEME_COLORS[$ref]+_} ]]; then
    printf "%s" "${THEME_COLORS[$ref]}"
  elif [[ -n $fallback && -n ${THEME_COLORS[$fallback]+_} ]]; then
    printf "%s" "${THEME_COLORS[$fallback]}"
  elif [[ -n $fallback ]]; then
    printf "%s" "$fallback"
  else
    printf "%s" "$ref"
  fi
}

resolve_gradient_color() {
  local color

  color=$(trim "$1")
  if [[ -n ${THEME_COLORS[$color]+_} ]]; then
    color="${THEME_COLORS[$color]}"
  fi

  printf "%s" "$color"
}

parse_gradient() {
  local spec="$1"
  local part color
  local -a parts

  GRADIENT_COLORS=()
  GRADIENT_ANGLE=""

  read -ra parts <<<"$spec"
  for part in "${parts[@]}"; do
    [[ -n $part ]] || continue

    if [[ $part =~ ^-?[0-9]+([.][0-9]+)?deg$ ]]; then
      GRADIENT_ANGLE="${part%deg}"
    else
      color=$(resolve_gradient_color "$part")
      GRADIENT_COLORS+=("$color")
    fi
  done
}

color_to_shell_hex() {
  local color r g b

  color=$(resolve_gradient_color "$1")

  if [[ $color =~ ^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$ ]]; then
    printf "#%s" "${color:1:6}"
  elif [[ $color =~ ^[Rr][Gg][Bb][Aa]?\(([0-9A-Fa-f]{6})([0-9A-Fa-f]{2})?\)$ ]]; then
    printf "#%s" "${BASH_REMATCH[1]}"
  elif [[ $color =~ ^[Rr][Gg][Bb][Aa]?\(([0-9]+),([0-9]+),([0-9]+)(,[0-9.]+)?\)$ ]]; then
    r=${BASH_REMATCH[1]}
    g=${BASH_REMATCH[2]}
    b=${BASH_REMATCH[3]}
    (( r > 255 )) && r=255
    (( g > 255 )) && g=255
    (( b > 255 )) && b=255
    printf "#%02x%02x%02x" "$r" "$g" "$b"
  elif [[ $color =~ ^0x[0-9A-Fa-f]{8}$ ]]; then
    printf "#%s" "${color:4:6}"
  else
    printf "%s" "$color"
  fi
}

hypr_gradient_value() {
  local spec color index

  spec=$(resolve_theme_ref "$1" "${2:-}")
  parse_gradient "$spec"

  if (( ${#GRADIENT_COLORS[@]} == 0 )); then
    printf '"%s"' "$spec"
  elif (( ${#GRADIENT_COLORS[@]} == 1 )); then
    printf '"%s"' "${GRADIENT_COLORS[0]}"
  else
    printf '{ colors = {'
    for index in "${!GRADIENT_COLORS[@]}"; do
      (( index > 0 )) && printf ','
      printf ' "%s"' "${GRADIENT_COLORS[$index]}"
    done
    printf ' }'
    [[ -n $GRADIENT_ANGLE ]] && printf ', angle = %s' "$GRADIENT_ANGLE"
    printf ' }'
  fi
}

gradient_start_value() {
  local spec

  spec=$(resolve_theme_ref "$1" "${2:-}")
  parse_gradient "$spec"

  if (( ${#GRADIENT_COLORS[@]} == 0 )); then
    color_to_shell_hex "$spec"
  else
    color_to_shell_hex "${GRADIENT_COLORS[0]}"
  fi
}

shell_gradient_value() {
  local spec index

  spec=$(resolve_theme_ref "$1" "${2:-}")
  parse_gradient "$spec"

  if (( ${#GRADIENT_COLORS[@]} == 0 )); then
    printf "%s" "$spec"
    return
  fi

  for index in "${!GRADIENT_COLORS[@]}"; do
    (( index > 0 )) && printf " "
    printf "%s" "${GRADIENT_COLORS[$index]}"
  done

  [[ -n $GRADIENT_ANGLE ]] && printf " %sdeg" "$GRADIENT_ANGLE"
}

add_template_value() {
  local key="$1"
  local value="$2"
  local rgb

  printf 's|{{ %s }}|%s|g\n' "$key" "$value" >>"$sed_script"
  printf 's|{{ %s_strip }}|%s|g\n' "$key" "${value#\#}" >>"$sed_script"

  if [[ $value =~ ^#[0-9A-Fa-f]{6}$ ]]; then
    rgb=$(hex_to_rgb "$value")
    printf 's|{{ %s_rgb }}|%s|g\n' "$key" "$rgb" >>"$sed_script"
  fi
}

add_mix_value() {
  local token="$1"
  local content fn start_key end_key amount start end value

  content="${token#\{\{}"
  content="${content%\}\}}"
  read -r fn start_key end_key amount <<<"$content"

  start="${THEME_COLORS[$start_key]:-}"
  end="${THEME_COLORS[$end_key]:-}"

  [[ $start =~ ^#[0-9A-Fa-f]{6}$ && $end =~ ^#[0-9A-Fa-f]{6}$ ]] || return

  value=$(mix_color "$start" "$end" "$amount")

  case "$fn" in
    mix)
      ;;
    mix_strip)
      value="${value#\#}"
      ;;
    mix_rgb)
      value=$(hex_to_rgb "$value")
      ;;
    *)
      return
      ;;
  esac

  printf 's|%s|%s|g\n' "$token" "$value" >>"$sed_script"
}

add_mix_values() {
  local tpl token
  local -A seen=()

  for tpl in "${template_files[@]}"; do
    while IFS= read -r token; do
      [[ -n ${seen[$token]:-} ]] && continue
      seen[$token]=1
      add_mix_value "$token"
    done < <(grep -hEo '\{\{[[:space:]]*mix(_strip|_rgb)?[[:space:]]+[A-Za-z0-9_]+[[:space:]]+[A-Za-z0-9_]+[[:space:]]+[0-9]+([.][0-9]+)?%?[[:space:]]*\}\}' "$tpl" 2>/dev/null || true)
  done
}

add_gradient_function_value() {
  local token="$1"
  local content fn key fallback value

  content="${token#\{\{}"
  content="${content%\}\}}"
  read -r fn key fallback <<<"$content"

  case "$fn" in
    hypr_gradient)
      value=$(hypr_gradient_value "$key" "$fallback")
      ;;
    gradient_start)
      value=$(gradient_start_value "$key" "$fallback")
      ;;
    shell_gradient)
      value=$(shell_gradient_value "$key" "$fallback")
      ;;
    *)
      return
      ;;
  esac

  printf 's|%s|%s|g\n' "$token" "$value" >>"$sed_script"
}

add_gradient_function_values() {
  local tpl token
  local -A seen=()

  for tpl in "${template_files[@]}"; do
    while IFS= read -r token; do
      [[ -n ${seen[$token]:-} ]] && continue
      seen[$token]=1
      add_gradient_function_value "$token"
    done < <(grep -hEo '\{\{[[:space:]]*(hypr_gradient|gradient_start|shell_gradient)[[:space:]]+[^}]+[[:space:]]*\}\}' "$tpl" 2>/dev/null || true)
  done
}


ze_render_templates() {
  local theme_dir="$1"
  local tpl filename output_path key

  ze_load_colors "$theme_dir/colors.toml" || return 0

  sed_script=$(mktemp)

  shopt -s nullglob
  template_files=("$ZE_TEMPLATES_PATH"/*.tpl)

  for key in "${!THEME_COLORS[@]}"; do
    add_template_value "$key" "${THEME_COLORS[$key]}"
  done

  add_mix_values
  add_gradient_function_values

  for tpl in "${template_files[@]}"; do
    filename=$(basename "$tpl" .tpl)
    output_path="$theme_dir/$filename"

    if [[ ! -f $output_path ]]; then
      sed -f "$sed_script" "$tpl" >"$output_path"
    fi
  done

  rm "$sed_script"
}
