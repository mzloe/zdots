# ze theme sync: add/update themes from the omarchy repo into themes/.
#
# Never deletes anything already in themes/, so your own themes and any theme
# omarchy drops stay put. Skipped: themes listed in themes/.sync-ignore (merged
# or removed on purpose), wallpapers with "omarchy" in the name, the
# Omarchy-branded Plymouth images (unlock.png, preview-unlock.png), vscode.json
# (VS Code is not themed here) and preview.* when the theme already has one.
# Nothing is applied until you commit: like makepkg with a PKGBUILD, the diff is
# shown first, with the files that are code rather than colours called out.

OMARCHY_REPO="https://github.com/omacom/omarchy"

ze_theme_sync() {
  local clone_dir="$ZE_CACHE_PATH/omarchy"
  local theme_path theme_name entry background sha ignored

  if [[ -d $clone_dir/.git ]]; then
    git -C "$clone_dir" pull --ff-only -q || ze_die "could not update $clone_dir"
  else
    mkdir -p "$(dirname "$clone_dir")"
    # A sparse, blobless clone only downloads themes/ (~65 MB), not the whole repo
    git clone -q --depth 1 --filter=blob:none --sparse "$OMARCHY_REPO" "$clone_dir" || ze_die "could not clone omarchy"
    git -C "$clone_dir" sparse-checkout set themes
  fi

  shopt -s nullglob
  [[ -d $clone_dir/themes ]] || ze_die "no themes/ in $clone_dir"

  mapfile -t ignored < <(sed -E 's/#.*//; /^[[:space:]]*$/d' "$ZE_THEMES_PATH/.sync-ignore" 2>/dev/null)

  for theme_path in "$clone_dir"/themes/*/; do
    theme_path=${theme_path%/}
    theme_name=${theme_path##*/}
    printf '%s\n' "${ignored[@]}" | grep -qx "$theme_name" && continue
    [[ -d $ZE_THEMES_PATH/$theme_name ]] || echo "new theme: $theme_name"
    mkdir -p "$ZE_THEMES_PATH/$theme_name"

    for entry in "$theme_path"/*; do
      case ${entry##*/} in unlock.png | preview-unlock.png | vscode.json) continue ;; esac
      # Our previews share one layout without the omarchy logo; keep them once made
      if [[ ${entry##*/} == preview.* ]] && compgen -G "$ZE_THEMES_PATH/$theme_name/preview.*" >/dev/null; then
        continue
      fi
      if [[ ${entry##*/} == backgrounds ]]; then
        mkdir -p "$ZE_THEMES_PATH/$theme_name/backgrounds"
        for background in "$entry"/*; do
          [[ ${background##*/} == *omarchy* ]] && continue
          cp -r "$background" "$ZE_THEMES_PATH/$theme_name/backgrounds/"
        done
      else
        cp -r "$entry" "$ZE_THEMES_PATH/$theme_name/"
      fi
    done
  done

  sha=$(git -C "$clone_dir" rev-parse HEAD)
  printf 'omarchy %s\nsynced %s\n' "$sha" "$(date -I)" >"$ZE_THEMES_PATH/.omarchy-version"

  echo "themes synced from omarchy @ ${sha:0:12}"
  ze_sync_review
}

# Theme files that are run rather than read: Hyprland dofile()s hyprland.lua,
# hyprlock and ghostty run commands named in their conf, nvim installs the repo
# named in neovim.lua.
ZE_THEME_CODE_FILES='hyprland\.lua|hyprlock\.conf|ghostty\.conf|neovim\.lua'

ze_sync_review() {
  local changes code answer

  git -C "$ZE_REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0

  # Intent-to-add, so new files show up in git diff like changed ones
  git -C "$ZE_REPO" add --intent-to-add -- "$ZE_THEMES_PATH"
  changes=$(git -C "$ZE_REPO" status --short -- "$ZE_THEMES_PATH")
  if [[ -z $changes ]]; then
    echo "nothing changed"
    return 0
  fi

  echo "changes:"
  sed 's/^/  /' <<<"$changes"

  code=$(grep -E "/($ZE_THEME_CODE_FILES)$" <<<"$changes" || true)
  if [[ -n $code ]]; then
    echo
    echo "these files are code, not colours (Hyprland runs hyprland.lua, hyprlock and"
    echo "ghostty run commands from their conf, nvim installs the repo in neovim.lua):"
    sed 's/^/  /' <<<"$code"
  fi

  echo
  if [[ -t 0 ]]; then
    read -rp "Show the diff? [Y/n] " answer
    [[ $answer =~ ^[Nn] ]] || git -C "$ZE_REPO" diff -- "$ZE_THEMES_PATH"
  fi
  echo "when it looks right: git add -A $ZE_THEMES_PATH && git commit"
}
