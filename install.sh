#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# OhMyMac installer — macOS-inspired look for GNOME 47–51 on any distribution.
# Run ./install.sh --help for options.

set -Eeuo pipefail

OHM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/common.sh
. "${OHM_ROOT}/lib/common.sh"
# shellcheck source=lib/distro.sh
. "${OHM_ROOT}/lib/distro.sh"
# shellcheck source=lib/packages.sh
. "${OHM_ROOT}/lib/packages.sh"
# shellcheck source=lib/build.sh
. "${OHM_ROOT}/lib/build.sh"
# shellcheck source=lib/themes.sh
. "${OHM_ROOT}/lib/themes.sh"
# shellcheck source=lib/extensions.sh
. "${OHM_ROOT}/lib/extensions.sh"
# shellcheck source=lib/settings.sh
. "${OHM_ROOT}/lib/settings.sh"
# shellcheck source=lib/gdm.sh
. "${OHM_ROOT}/lib/gdm.sh"
# shellcheck source=lib/mactahoe.sh
. "${OHM_ROOT}/lib/mactahoe.sh"

usage() {
  cat <<EOF
${OHM_NAME} ${OHM_VERSION} — macOS-inspired theme suite for GNOME

Usage: ./install.sh [options]

Without options an interactive install runs with the recommended set.

Components:
  --all                 Everything below, including the "full" extension
                        profile and the login screen
  --themes-only         GTK 3/GTK 4/libadwaita/Shell themes only
  --no-icons            Skip the MacTahoe icon theme
  --no-cursors          Skip the macOS cursor theme
  --no-fonts            Skip font setup (Inter, or SF Pro if present)
  --no-wallpaper        Skip the OhMyMac wallpapers
  --no-extensions       Skip GNOME Shell extensions
  --extensions PROFILE  minimal | recommended (default) | full
  --no-settings         Do not change any GNOME settings
  --no-flatpak          Skip Flatpak integration
  --gdm                 Also style the login screen (needs root)

Appearance:
  --theme THEME         hybrid (default: MacTahoe base + OhMyMac Tahoe layer)
                        | ohmymac (OhMyMac's own GTK/Shell theme only)
  --variant VARIANT     auto (default, follow system) | light | dark
  --accent COLOR        blue (default) | teal | green | yellow | orange |
                        red | pink | purple | slate

Installation:
  --system              Install themes/icons for all users (needs root)
  --dest DIR            Stage files under DIR for packaging; implies
                        --themes-only and changes nothing on this system
  --no-deps             Never call the package manager
  --allow-incompatible  Install extensions not marked for this GNOME
  --update-extensions   Re-download extensions that are already installed

General:
  -y, --yes             Assume "yes" for every question
  -n, --dry-run         Show what would be done, change nothing
  -v, --verbose         Print every command
  -h, --help            Show this help
  -V, --version         Show the version

Examples:
  ./install.sh                       # recommended setup
  ./install.sh --all -y              # everything, no questions
  ./install.sh --themes-only         # just the themes
  ./install.sh --variant dark --accent purple
  sudo ./install.sh --system --themes-only
EOF
}

# --- Options -------------------------------------------------------------------

WANT_ICONS=1 WANT_CURSORS=1 WANT_FONTS=1 WANT_WALLPAPER=1
WANT_EXTENSIONS=1 WANT_SETTINGS=1 WANT_FLATPAK=1 WANT_GDM=0
EXT_PROFILE="recommended"
THEME_MODE="hybrid"
VARIANT="auto"
OHM_ACCENT="blue"
INTERACTIVE=1

parse_args() {
  while (($#)); do
    case "$1" in
      --all)                WANT_GDM=1; EXT_PROFILE=full; INTERACTIVE=0 ;;
      --themes-only)        WANT_ICONS=0 WANT_CURSORS=0 WANT_FONTS=0 WANT_WALLPAPER=0
                            WANT_EXTENSIONS=0 WANT_FLATPAK=0; INTERACTIVE=0 ;;
      --no-icons)           WANT_ICONS=0 ;;
      --no-cursors)         WANT_CURSORS=0 ;;
      --no-fonts)           WANT_FONTS=0 ;;
      --no-wallpaper)       WANT_WALLPAPER=0 ;;
      --no-extensions)      WANT_EXTENSIONS=0 ;;
      --extensions)         EXT_PROFILE="${2:?--extensions needs a profile}"; shift ;;
      --extensions=*)       EXT_PROFILE="${1#*=}" ;;
      --no-settings)        WANT_SETTINGS=0 ;;
      --no-flatpak)         WANT_FLATPAK=0 ;;
      --gdm)                WANT_GDM=1 ;;
      --variant)            VARIANT="${2:?--variant needs a value}"; shift ;;
      --variant=*)          VARIANT="${1#*=}" ;;
      --accent)             OHM_ACCENT="${2:?--accent needs a value}"; shift ;;
      --theme)              THEME_MODE="${2:?--theme needs a value}"; shift ;;
      --theme=*)            THEME_MODE="${1#*=}" ;;
      --accent=*)           OHM_ACCENT="${1#*=}" ;;
      --system)             OHM_SYSTEM=1 ;;
      --dest)               OHM_DEST="${2:?--dest needs a directory}"; shift ;;
      --dest=*)             OHM_DEST="${1#*=}" ;;
      --no-deps)            OHM_NO_DEPS=1 ;;
      --allow-incompatible) OHM_EXT_ALLOW_INCOMPATIBLE=1 ;;
      --update-extensions)  OHM_EXT_UPDATE=1 ;;
      -y|--yes)             OHM_ASSUME_YES=1; INTERACTIVE=0 ;;
      -n|--dry-run)         OHM_DRY_RUN=1 ;;
      -v|--verbose)         OHM_VERBOSE=1 ;;
      -h|--help)            usage; exit 0 ;;
      -V|--version)         echo "${OHM_NAME} ${OHM_VERSION}"; exit 0 ;;
      *)                    usage >&2; die "Unknown option: $1" ;;
    esac
    shift
  done

  case "${VARIANT}" in auto|light|dark) ;; *) die "--variant must be auto, light or dark" ;; esac
  case "${THEME_MODE}" in hybrid|ohmymac) ;; *) die "--theme must be hybrid or ohmymac" ;; esac
  case "${OHM_ACCENT}" in
    blue|teal|green|yellow|orange|red|pink|purple|slate) ;;
    *) die "Unknown accent: ${OHM_ACCENT}" ;;
  esac
  case "${EXT_PROFILE}" in minimal|recommended|full) ;; *) die "Unknown extension profile: ${EXT_PROFILE}" ;; esac

  if [[ -n "${OHM_DEST:-}" ]]; then
    WANT_ICONS=0 WANT_CURSORS=0 WANT_FONTS=0 WANT_WALLPAPER=0
    WANT_EXTENSIONS=0 WANT_SETTINGS=0 WANT_FLATPAK=0 WANT_GDM=0
    INTERACTIVE=0
  fi
  if [[ "${OHM_SYSTEM:-0}" == 1 ]]; then
    # Per-user parts belong to each user's own run.
    WANT_EXTENSIONS=0 WANT_SETTINGS=0 WANT_FLATPAK=0 WANT_WALLPAPER=0 WANT_FONTS=0
  fi
}

# --- Interactive questions -------------------------------------------------------

ask_choices() {
  [[ "${INTERACTIVE}" == 1 && -t 0 ]] || return 0
  log_step "Choose what to install"
  confirm "MacTahoe icon theme?" y          || WANT_ICONS=0
  confirm "macOS cursor theme?" y           || WANT_CURSORS=0
  confirm "Inter font (or SF Pro if you have it)?" y || WANT_FONTS=0
  confirm "OhMyMac wallpapers?" y           || WANT_WALLPAPER=0
  if (( OHM_GNOME_MAJOR > 0 )); then
    if confirm "GNOME Shell extensions (dock, blur, …)?" y; then
      confirm "Use the full extension set (more tweaks)?" n && EXT_PROFILE=full
    else
      WANT_EXTENSIONS=0
    fi
    confirm "Style the login screen too (needs root)?" n && WANT_GDM=1
  fi
  confirm "Apply the macOS-like GNOME settings (backed up first)?" y || WANT_SETTINGS=0
}

# --- Steps -----------------------------------------------------------------------

resolve_variant() {
  local scheme="'default'"
  case "${VARIANT}" in
    light) OHM_COLOR_SCHEME="default" ;;
    dark)  OHM_COLOR_SCHEME="prefer-dark" ;;
    auto)
      has gsettings && scheme="$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "'default'")"
      OHM_COLOR_SCHEME="${scheme//\'/}"
      ;;
  esac
  if [[ "${OHM_COLOR_SCHEME}" == prefer-dark ]]; then
    OHM_GTK_THEME="OhMyMac-Dark" OHM_ICON_THEME="MacTahoe-dark"
  else
    [[ "${OHM_COLOR_SCHEME}" == prefer-light ]] || OHM_COLOR_SCHEME="default"
    OHM_GTK_THEME="OhMyMac-Light" OHM_ICON_THEME="MacTahoe-light"
  fi
  export OHM_COLOR_SCHEME OHM_GTK_THEME OHM_ICON_THEME OHM_ACCENT
}

install_sync_helper() {
  local bindir="${HOME}/.local/bin" autostart="${XDG_CONFIG_HOME}/autostart"
  log_step "Light/dark sync helper"
  run mkdir -p "${bindir}" "${autostart}"
  run install -m755 "${OHM_ROOT}/bin/ohmymac-sync" "${bindir}/ohmymac-sync"
  if [[ "${OHM_DRY_RUN}" != 1 ]]; then
    sed "s|@BINDIR@|${bindir}|g" "${OHM_ROOT}/data/ohmymac-sync.desktop" >"${autostart}/ohmymac-sync.desktop"
  fi
  manifest_add "${bindir}/ohmymac-sync" "${autostart}/ohmymac-sync.desktop"
  log_ok "GTK 3 and the Shell theme now follow the light/dark switch"
}

apply_settings() {
  log_step "GNOME settings"
  apply_preset desktop
  [[ "${WANT_FONTS}" == 1 && -n "${OHM_UI_FONT:-}" ]] && apply_preset fonts
  # Never point GNOME at an icon or cursor theme that failed to download.
  if [[ "${WANT_ICONS}" == 1 ]] && { [[ "${OHM_DRY_RUN}" == 1 ]] || icon_theme_present "${OHM_ICON_THEME}"; }; then
    apply_preset icons
  fi
  if [[ "${WANT_CURSORS}" == 1 ]] && { [[ "${OHM_DRY_RUN}" == 1 ]] || icon_theme_present macOS; }; then
    apply_preset cursors
  fi
  [[ "${WANT_WALLPAPER}" == 1 && -n "${OHM_WALLPAPER_LIGHT:-}" ]] && apply_preset wallpaper
  if [[ "${WANT_EXTENSIONS}" == 1 ]]; then
    apply_preset extensions
    apply_dock_favorites
  fi
  return 0
}

summary() {
  log_step "Done"
  if [[ -n "${OHM_DEST:-}" ]]; then
    log_ok "Themes staged in ${OHM_DEST}"
    return
  fi
  log_ok "${OHM_NAME} ${OHM_VERSION} is installed."
  if [[ "${WANT_EXTENSIONS}" == 1 || "${WANT_GDM}" == 1 ]]; then
    log_info "Log out and back in to load new extensions (Wayland cannot restart the Shell)."
  fi
  log_info "Change light/dark and accent colour in Settings → Appearance."
  log_info "Undo everything with ./uninstall.sh"
}

main() {
  parse_args "$@"

  printf '%s%s %s%s — macOS look for GNOME\n' "${_c_bold}" "${OHM_NAME}" "${OHM_VERSION}" "${_c_reset}"
  [[ "${OHM_DRY_RUN}" == 1 ]] && log_warn "Dry run: nothing will be changed."

  if [[ "${EUID}" -eq 0 && "${OHM_SYSTEM:-0}" != 1 && -z "${OHM_DEST:-}" && "${OHM_ALLOW_ROOT:-0}" != 1 ]]; then
    die "Do not run as root. Run as your user; sudo is requested only when needed (or use --system)."
  fi

  detect_distro
  detect_gnome
  detect_sudo
  print_environment
  ask_choices
  ohm_init_tmp

  if [[ "${OHM_NO_DEPS:-0}" != 1 ]]; then
    log_step "Dependencies"
    [[ -n "${OHM_DEST:-}" ]] || install_deps "${OHM_DEPS_CORE[@]}"
    [[ -d "${OHM_BUILD}/OhMyMac-Light" ]] || install_deps "${OHM_DEPS_BUILD[@]}"
    log_ok "Dependencies checked"
  fi

  if [[ ! -d "${OHM_BUILD}/OhMyMac-Light" || "${OHM_REBUILD:-1}" == 1 ]]; then
    if _sass_compiler >/dev/null; then
      build_themes
    elif [[ ! -d "${OHM_BUILD}/OhMyMac-Light" ]]; then
      die "No Sass compiler (sassc or dart-sass) and no prebuilt build/ directory."
    fi
  fi

  resolve_variant

  # OhMyMac's own themes are always installed: they are the fallback, the
  # --theme ohmymac option and the source of the login-screen styling.
  install_themes
  local base="OhMyMac"
  if [[ "${THEME_MODE}" == hybrid ]] && install_mactahoe; then
    base="MacTahoe"
  fi
  OHM_GTK_THEME="${base}-${OHM_GTK_THEME#*-}"
  export OHM_GTK_THEME
  if [[ -z "${OHM_DEST:-}" && "${OHM_SYSTEM:-0}" != 1 ]]; then
    if [[ "${base}" == MacTahoe ]]; then
      install_mactahoe_libadwaita
    else
      install_libadwaita
    fi
    install_sync_helper
  fi
  [[ "${WANT_FLATPAK}" == 1 ]]   && install_flatpak_integration
  [[ "${WANT_FONTS}" == 1 ]]     && install_fonts
  [[ "${WANT_ICONS}" == 1 ]]     && install_icons
  [[ "${WANT_CURSORS}" == 1 ]]   && install_cursors
  [[ "${WANT_WALLPAPER}" == 1 ]] && install_wallpapers
  if [[ "${WANT_EXTENSIONS}" == 1 ]]; then
    install_extensions "${EXT_PROFILE}"
  elif (( OHM_GNOME_MAJOR > 0 )) && [[ -z "${OHM_DEST:-}" && "${OHM_SYSTEM:-0}" != 1 ]]; then
    # The Shell theme cannot load without User Themes.
    install_extensions minimal
  fi
  [[ "${WANT_SETTINGS}" == 1 ]]  && apply_settings
  [[ "${WANT_GDM}" == 1 ]]       && install_gdm

  if [[ "${OHM_DRY_RUN}" != 1 && -z "${OHM_DEST:-}" && "${OHM_SYSTEM:-0}" != 1 ]]; then
    mkdir -p "${OHM_STATE_DIR}"
    printf '%s\n' "${OHM_VERSION}" >"${OHM_STATE_DIR}/version"
  fi
  summary
}

main "$@"
