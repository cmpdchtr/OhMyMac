#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# OhMyMac uninstaller — removes exactly what install.sh recorded and puts
# your previous GNOME settings and files back.

set -Eeuo pipefail

OHM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/common.sh
. "${OHM_ROOT}/lib/common.sh"
# shellcheck source=lib/distro.sh
. "${OHM_ROOT}/lib/distro.sh"
# shellcheck source=lib/build.sh
. "${OHM_ROOT}/lib/build.sh"
# shellcheck source=lib/extensions.sh
. "${OHM_ROOT}/lib/extensions.sh"
# shellcheck source=lib/settings.sh
. "${OHM_ROOT}/lib/settings.sh"
# shellcheck source=lib/gdm.sh
. "${OHM_ROOT}/lib/gdm.sh"

usage() {
  cat <<EOF
${OHM_NAME} ${OHM_VERSION} — uninstaller

Usage: ./uninstall.sh [options]

  --gdm             Also restore the stock login screen (needs root)
  --system          Remove system-wide themes/icons installed with --system
  --keep-settings   Do not restore the previous GNOME settings
  -y, --yes         Do not ask for confirmation
  -n, --dry-run     Show what would be removed
  -v, --verbose     Print every command
  -h, --help        Show this help
EOF
}

WANT_GDM=0 KEEP_SETTINGS=0

parse_args() {
  while (($#)); do
    case "$1" in
      --gdm)            WANT_GDM=1 ;;
      --system)         OHM_SYSTEM=1 ;;
      --keep-settings)  KEEP_SETTINGS=1 ;;
      -y|--yes)         OHM_ASSUME_YES=1 ;;
      -n|--dry-run)     OHM_DRY_RUN=1 ;;
      -v|--verbose)     OHM_VERBOSE=1 ;;
      -h|--help)        usage; exit 0 ;;
      *)                usage >&2; die "Unknown option: $1" ;;
    esac
    shift
  done
}

# Only paths under these roots are ever deleted from the manifest.
_safe_path() {
  local path="$1"
  [[ -n "${path}" && "${path}" == /* && "${path}" != *"/../"* ]] || return 1
  case "${path}" in
    "${XDG_DATA_HOME}"/?*|"${XDG_CONFIG_HOME}"/?*|"${HOME}/.themes"/?*|"${HOME}/.icons"/?*|"${HOME}/.local/bin"/?*) return 0 ;;
  esac
  return 1
}

remove_manifest() {
  [[ -r "${OHM_MANIFEST}" ]] || { log_info "No install manifest found."; return 0; }
  local entry
  log_step "Removing installed files"
  while IFS= read -r entry; do
    case "${entry}" in
      extension:*)
        local uuid="${entry#extension:}" path
        extension_disable "${uuid}"
        path="${OHM_USER_EXT_DIR}/${uuid}"
        if [[ -d "${path}" ]]; then
          run rm -rf "${path}"
          log_ok "Extension ${uuid}"
        fi
        ;;
      flatpak-override)
        if has flatpak; then
          run flatpak override --user \
            --nofilesystem=xdg-config/gtk-3.0 --nofilesystem=xdg-config/gtk-4.0 \
            --nofilesystem=xdg-data/themes --nofilesystem="${HOME}/.themes" \
            --nofilesystem=xdg-data/icons --nofilesystem="${HOME}/.icons" || true
          log_ok "Flatpak overrides"
        fi
        ;;
      *)
        if ! _safe_path "${entry}"; then
          log_warn "Refusing to remove unexpected path: ${entry}"
        elif [[ -e "${entry}" || -L "${entry}" ]]; then
          run rm -rf "${entry}"
          log_ok "${entry/#${HOME}/\~}"
        fi
        ;;
    esac
  done <"${OHM_MANIFEST}"
}

remove_system() {
  log_step "Removing system-wide files"
  local name
  for name in OhMyMac-Light OhMyMac-Dark MacTahoe-Light MacTahoe-Dark; do
    [[ -d "/usr/share/themes/${name}" ]] && run_root rm -rf "/usr/share/themes/${name}"
  done
  for name in MacTahoe MacTahoe-light MacTahoe-dark macOS macOS-White; do
    [[ -d "/usr/share/icons/${name}" ]] && run_root rm -rf "/usr/share/icons/${name}"
  done
  log_ok "System themes removed"
}

reset_theme_names() {
  has gsettings || return 0
  local current
  current="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || true)"
  if [[ "${current}" == "'OhMyMac-"* || "${current}" == "'MacTahoe-"* ]]; then
    run gsettings reset org.gnome.desktop.interface gtk-theme
  fi
}

main() {
  parse_args "$@"
  detect_distro
  detect_sudo

  printf '%s%s %s%s — uninstall\n' "${_c_bold}" "${OHM_NAME}" "${OHM_VERSION}" "${_c_reset}"
  [[ "${OHM_DRY_RUN}" == 1 ]] && log_warn "Dry run: nothing will be changed."
  confirm "Remove OhMyMac and restore your previous setup?" y || exit 0

  if [[ "${KEEP_SETTINGS}" != 1 ]]; then
    log_step "Restoring GNOME settings"
    # Before removing extensions: their schemas are needed to restore them.
    restore_settings
  fi

  # Stop the light/dark watcher of this session.
  run pkill -u "${USER:-$(id -un)}" -f 'ohmymac-sync' 2>/dev/null || true

  remove_manifest
  restore_backups
  [[ "${KEEP_SETTINGS}" == 1 ]] || reset_theme_names
  [[ "${OHM_SYSTEM:-0}" == 1 ]] && remove_system
  [[ "${WANT_GDM}" == 1 ]] && uninstall_gdm

  if [[ "${OHM_DRY_RUN}" != 1 ]]; then
    rm -rf "${OHM_STATE_DIR}" "${OHM_CACHE_DIR}"
  fi

  log_step "Done"
  log_ok "OhMyMac has been removed. Log out and back in to finish."
}

main "$@"
