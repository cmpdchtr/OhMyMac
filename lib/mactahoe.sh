# shellcheck shell=bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# OhMyMac — MacTahoe base theme (vinceliuice/MacTahoe-gtk-theme, MIT).
#
# MacTahoe's GTK 3, GTK 4 and Shell styling is the most faithful macOS
# rendition for GNOME, so the default "hybrid" install uses it as the base
# and layers OhMyMac on top (Liquid Glass, Dock, menu bar, Tahoe sidebar,
# light/dark switching, multi-distro installer).
#
# Only the project's prebuilt release archives are used: they are downloaded
# at a pinned commit, checked against SHA-256 sums and unpacked. No upstream
# script is executed.

OHM_MACTAHOE_REPO="${OHM_MACTAHOE_REPO:-https://raw.githubusercontent.com/vinceliuice/MacTahoe-gtk-theme}"
OHM_MACTAHOE_REF="${OHM_MACTAHOE_REF:-1e45e19f510edb8cde18fa84d6cd5319f60b086b}"
declare -A OHM_MACTAHOE_SHA256=(
  [MacTahoe-Dark]=08e816e5352247955d1cfa64b44af0aeee77cfbc52b52b4f4d4becf650cf5e15
  [MacTahoe-Light]=cfbc592771b487e51375f28d4a3d25cb94d3abaaaece57d6b371d8186d308991
)

_sha256() {
  if has sha256sum; then sha256sum "$1" | awk '{print $1}'
  else shasum -a 256 "$1" | awk '{print $1}'
  fi
}

# Rewrites relative asset URLs so a stylesheet works from any location.
_absolute_assets() {
  local theme_dir="$1" css="$2"
  sed -E "s#url\\(\"(assets|windows-assets)/#url(\"file://${theme_dir}/gtk-4.0/\\1/#g" "${css}"
}

# mactahoe_libadwaita_css <themes-dir> — prints one libadwaita stylesheet
# that follows the system light/dark switch: the light sheet as is, the dark
# sheet folded into @media (prefers-color-scheme: dark) by cssmerge.awk.
mactahoe_libadwaita_css() {
  local themes="$1" dark_abs="${OHM_TMP}/mactahoe-dark-abs.css"
  printf '/* OhMyMac %s — MacTahoe base (light + dark), managed file. */\n' "${OHM_VERSION}"
  _absolute_assets "${themes}/MacTahoe-Light" "${themes}/MacTahoe-Light/gtk-4.0/gtk.css"
  _absolute_assets "${themes}/MacTahoe-Dark" "${themes}/MacTahoe-Dark/gtk-4.0/gtk.css" >"${dark_abs}"
  awk -f "${OHM_ROOT}/lib/cssmerge.awk" "${dark_abs}" "${dark_abs}"
  # Tahoe details MacTahoe does not have yet (floating sidebar, accent
  # sidebar symbols); see src/sass/gtk4/_hybrid.scss.
  if [[ -f "${OHM_BUILD}/libadwaita/hybrid.css" ]]; then
    cat "${OHM_BUILD}/libadwaita/hybrid.css"
  fi
}

install_mactahoe() {
  local themes variant archive stage="${OHM_TMP}/mactahoe"
  themes="$(ohm_themes_dir)"
  log_step "Base theme: MacTahoe (vinceliuice, MIT) @ ${OHM_MACTAHOE_REF:0:7}"
  run mkdir -p "${stage}"

  for variant in MacTahoe-Light MacTahoe-Dark; do
    archive="${stage}/${variant}.tar.xz"
    if ! fetch "${OHM_MACTAHOE_REPO}/${OHM_MACTAHOE_REF}/release/${variant}.tar.xz" "${archive}"; then
      log_warn "Could not download ${variant}; falling back to the OhMyMac theme."
      return 1
    fi
    if [[ "${OHM_DRY_RUN}" != 1 && "$(_sha256 "${archive}")" != "${OHM_MACTAHOE_SHA256[${variant}]}" ]]; then
      log_warn "${variant}: checksum mismatch; falling back to the OhMyMac theme."
      return 1
    fi
    run tar -xJf "${archive}" -C "${stage}"
    _install_tree "${stage}/${variant}" "${themes}/${variant}"
    if [[ "${OHM_SYSTEM:-0}" != 1 && -z "${OHM_DEST:-}" ]]; then
      manifest_add "${themes}/${variant}"
      if [[ ! -e "${HOME}/.themes/${variant}" || -L "${HOME}/.themes/${variant}" ]]; then
        run mkdir -p "${HOME}/.themes"
        run ln -sfn "${themes}/${variant}" "${HOME}/.themes/${variant}"
        manifest_add "${HOME}/.themes/${variant}"
      fi
    fi
    log_ok "${variant}"
  done
  return 0
}

install_mactahoe_libadwaita() {
  local target="${XDG_CONFIG_HOME}/gtk-4.0/gtk.css" themes
  themes="$(ohm_themes_dir)"
  log_step "Styling libadwaita / GTK 4 apps (MacTahoe + OhMyMac Tahoe layer)"
  run mkdir -p "$(dirname "${target}")"
  backup_file "${target}"
  backup_file "${XDG_CONFIG_HOME}/gtk-4.0/gtk-dark.css"
  if [[ "${OHM_DRY_RUN}" != 1 ]]; then
    mactahoe_libadwaita_css "${themes}" >"${target}"
  fi
  manifest_add "${target}"
  log_ok "${target/#${HOME}/\~} (follows light/dark automatically)"
}
