# shellcheck shell=bash disable=SC2034  # variables are consumed by sourcing scripts
# SPDX-License-Identifier: GPL-3.0-or-later
#
# OhMyMac — installs the GTK/Shell themes, the libadwaita stylesheet,
# wallpapers, fonts, icons, cursors and Flatpak integration.

# Where themes go. --system → /usr/share/themes, --dest → staging dir
# (packaging), default → per-user.
ohm_themes_dir() {
  if [[ -n "${OHM_DEST:-}" ]]; then
    echo "${OHM_DEST}/usr/share/themes"
  elif [[ "${OHM_SYSTEM:-0}" == 1 ]]; then
    echo "/usr/share/themes"
  else
    echo "${XDG_DATA_HOME}/themes"
  fi
}

_install_tree() {
  # _install_tree <src> <dst> — replaces dst with a copy of src.
  local src="$1" dst="$2"
  if [[ "${OHM_SYSTEM:-0}" == 1 && -z "${OHM_DEST:-}" ]]; then
    run_root rm -rf "${dst}"
    run_root mkdir -p "$(dirname "${dst}")"
    run_root cp -a "${src}" "${dst}"
  else
    run rm -rf "${dst}"
    run mkdir -p "$(dirname "${dst}")"
    run cp -a "${src}" "${dst}"
  fi
}

install_themes() {
  local themes variant dir stage
  themes="$(ohm_themes_dir)"
  log_step "Installing themes → ${themes/#${HOME}/\~}"

  [[ -d "${OHM_BUILD}/OhMyMac-Light" ]] || build_themes

  stage="${OHM_TMP}/themes"
  run mkdir -p "${stage}"
  for variant in "${OHM_VARIANTS[@]}"; do
    dir="${stage}/OhMyMac-${variant}"
    run cp -a "${OHM_BUILD}/OhMyMac-${variant}" "${dir}"
    [[ "${OHM_DRY_RUN}" == 1 ]] || shell_finalize "${dir}" "${variant}"
    _install_tree "${dir}" "${themes}/OhMyMac-${variant}"
    [[ "${OHM_SYSTEM:-0}" == 1 || -n "${OHM_DEST:-}" ]] || manifest_add "${themes}/OhMyMac-${variant}"
    log_ok "OhMyMac-${variant}"
  done

  # GTK 3 inside Flatpak sandboxes only searches ~/.themes, not
  # $XDG_DATA_HOME/themes; mirror the user install there via symlinks.
  if [[ "${OHM_SYSTEM:-0}" != 1 && -z "${OHM_DEST:-}" ]]; then
    run mkdir -p "${HOME}/.themes"
    for variant in "${OHM_VARIANTS[@]}"; do
      if [[ ! -e "${HOME}/.themes/OhMyMac-${variant}" || -L "${HOME}/.themes/OhMyMac-${variant}" ]]; then
        run ln -sfn "${themes}/OhMyMac-${variant}" "${HOME}/.themes/OhMyMac-${variant}"
        manifest_add "${HOME}/.themes/OhMyMac-${variant}"
      fi
    done
  fi
}

# libadwaita ignores gtk-theme; per-user CSS is the supported way in.
install_libadwaita() {
  local target="${XDG_CONFIG_HOME}/gtk-4.0/gtk.css"
  log_step "Styling libadwaita / GTK 4 apps"
  [[ -f "${OHM_BUILD}/libadwaita/gtk.css" ]] || build_themes
  run mkdir -p "$(dirname "${target}")"
  backup_file "${target}"
  run cp -f "${OHM_BUILD}/libadwaita/gtk.css" "${target}"
  manifest_add "${target}"
  log_ok "${target/#${HOME}/\~}"
}

install_flatpak_integration() {
  has flatpak || return 0
  log_step "Flatpak integration"
  run flatpak override --user \
    --filesystem=xdg-config/gtk-3.0:ro \
    --filesystem=xdg-config/gtk-4.0:ro \
    --filesystem=xdg-data/themes:ro \
    --filesystem="${HOME}/.themes:ro" \
    --filesystem=xdg-data/icons:ro \
    --filesystem="${HOME}/.icons:ro"
  manifest_add "flatpak-override"
  log_ok "Flatpak apps can read OhMyMac themes, icons and libadwaita CSS"
}

# --- Wallpapers ---------------------------------------------------------------

install_wallpapers() {
  local dir="${XDG_DATA_HOME}/backgrounds/ohmymac" props="${XDG_DATA_HOME}/gnome-background-properties"
  log_step "Wallpapers"
  run mkdir -p "${dir}" "${props}"
  run cp -f "${OHM_SRC}/wallpapers/"*.svg "${dir}/"
  if [[ "${OHM_DRY_RUN}" != 1 ]]; then
    sed "s|@DIR@|${dir}|g" "${OHM_SRC}/wallpapers/ohmymac.xml.in" >"${props}/ohmymac.xml"
  fi
  manifest_add "${dir}" "${props}/ohmymac.xml"
  OHM_WALLPAPER_LIGHT="file://${dir}/ohmymac-light.svg"
  OHM_WALLPAPER_DARK="file://${dir}/ohmymac-dark.svg"
  log_ok "Light/dark wallpaper pair installed"
}

# --- Fonts --------------------------------------------------------------------

OHM_INTER_URL="${OHM_INTER_URL:-https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip}"

# Prints the installed Inter family name: static "Inter" is preferred over
# "Inter Variable" because GNOME's font picker handles it better.
_inter_family() {
  has fc-list || return 0
  local families
  families="$(fc-list : family 2>/dev/null | tr ',' '\n')"
  if grep -qx 'Inter' <<<"${families}"; then
    echo "Inter"
  elif grep -qx 'Inter Variable' <<<"${families}"; then
    echo "Inter Variable"
  fi
  return 0
}

install_fonts() {
  log_step "Fonts"
  if has fc-list && grep -qiE 'SF Pro (Text|Display)' <<<"$(fc-list : family 2>/dev/null)"; then
    OHM_UI_FONT="SF Pro Text"
    log_ok "Using SF Pro (found on the system)"
    return 0
  fi

  install_deps font-inter
  if [[ -z "$(_inter_family)" && "${OHM_DRY_RUN}" != 1 ]]; then
    local fontdir="${XDG_DATA_HOME}/fonts/Inter" zip="${OHM_TMP}/inter.zip"
    log_info "Downloading Inter (SIL OFL 1.1)"
    if fetch "${OHM_INTER_URL}" "${zip}"; then
      mkdir -p "${fontdir}" "${OHM_TMP}/inter"
      unzip -qo "${zip}" -d "${OHM_TMP}/inter"
      find "${OHM_TMP}/inter" \( -name 'InterVariable*.ttf' -o -name 'Inter-*.otf' \) -exec cp -f {} "${fontdir}/" \;
      manifest_add "${fontdir}"
      if has fc-cache; then fc-cache -f "${fontdir}" >/dev/null 2>&1 || true; fi
    else
      log_warn "Could not download Inter; keeping the current UI font."
      return 0
    fi
  fi
  OHM_UI_FONT="$(_inter_family)"
  OHM_UI_FONT="${OHM_UI_FONT:-Inter}"
  log_ok "UI font: ${OHM_UI_FONT} (put SF Pro in ~/.local/share/fonts to use it instead)"
}

# --- Icons & cursors (fetched from their upstream projects) -------------------

OHM_ICONS_REPO="${OHM_ICONS_REPO:-https://github.com/vinceliuice/MacTahoe-icon-theme.git}"
# Pinned to a reviewed commit: the icon theme's own install.sh is executed.
OHM_ICONS_REF="${OHM_ICONS_REF:-839848b9a8a38a92a6936e30c4abe35cc6f2546d}"
OHM_CURSORS_URL="${OHM_CURSORS_URL:-https://github.com/ful1e5/apple_cursor/releases/latest/download/macOS.tar.xz}"

# icon_theme_present <name> — true when an icon or cursor theme is installed.
icon_theme_present() {
  local dir
  for dir in "${XDG_DATA_HOME}/icons" "${HOME}/.icons" /usr/share/icons /usr/local/share/icons; do
    [[ -f "${dir}/$1/index.theme" ]] && return 0
  done
  return 1
}

icons_dir() {
  if [[ "${OHM_SYSTEM:-0}" == 1 ]]; then echo /usr/share/icons; else echo "${XDG_DATA_HOME}/icons"; fi
}

install_icons() {
  local dest src
  dest="$(icons_dir)"
  log_step "Icons: MacTahoe (vinceliuice) → ${dest/#${HOME}/\~}"
  install_deps git
  has git || { log_warn "git is missing; skipping icons."; return 0; }

  src="${OHM_TMP}/MacTahoe-icon-theme"
  if [[ "${OHM_DRY_RUN}" != 1 ]] &&
     ! { git init -q "${src}" &&
         git -C "${src}" fetch -q --depth 1 "${OHM_ICONS_REPO}" "${OHM_ICONS_REF}" &&
         git -C "${src}" checkout -q FETCH_HEAD; } 2>/dev/null; then
    log_warn "Could not fetch the icon theme; skipping."
    return 0
  fi

  if [[ "${OHM_SYSTEM:-0}" == 1 ]]; then
    run_root bash "${src}/install.sh" -d "${dest}"
  else
    run bash "${src}/install.sh" -d "${dest}"
    manifest_add "${dest}/MacTahoe" "${dest}/MacTahoe-light" "${dest}/MacTahoe-dark"
  fi
  log_ok "MacTahoe icons"
}

install_cursors() {
  local dest archive
  dest="$(icons_dir)"
  log_step "Cursors: macOS (ful1e5/apple_cursor)"
  archive="${OHM_TMP}/macOS.tar.xz"
  fetch "${OHM_CURSORS_URL}" "${archive}" || { log_warn "Could not download cursors; skipping."; return 0; }
  run mkdir -p "${OHM_TMP}/cursors"
  run tar -xJf "${archive}" -C "${OHM_TMP}/cursors"
  local theme
  for theme in macOS macOS-White; do
    if [[ "${OHM_SYSTEM:-0}" == 1 ]]; then
      run_root rm -rf "${dest:?}/${theme}"
      run_root mkdir -p "${dest}"
      run_root cp -a "${OHM_TMP}/cursors/${theme}" "${dest}/"
    else
      run rm -rf "${dest:?}/${theme}"
      run mkdir -p "${dest}"
      run cp -a "${OHM_TMP}/cursors/${theme}" "${dest}/"
      manifest_add "${dest}/${theme}"
    fi
  done
  log_ok "macOS cursors"
}
