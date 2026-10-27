# shellcheck shell=bash disable=SC2034  # variables are consumed by sourcing scripts
# SPDX-License-Identifier: GPL-3.0-or-later
#
# OhMyMac — environment detection: distribution family, package manager,
# immutable systems, GNOME Shell version and session type.

OHM_DISTRO_ID=""
OHM_DISTRO_NAME=""
OHM_DISTRO_FAMILY=""   # debian | fedora | arch | suse | void | alpine | gentoo | solus | nixos | unknown
OHM_PKG=""             # apt | dnf | pacman | zypper | xbps | apk | emerge | eopkg | rpm-ostree | nix | ""
OHM_IMMUTABLE=0
OHM_GNOME_VERSION=""   # e.g. 51.1
OHM_GNOME_MAJOR=0
OHM_SESSION_TYPE="${XDG_SESSION_TYPE:-unknown}"

# Minimum and target GNOME releases. Older Shells still work with the GTK
# themes, but Shell styling and extensions are only promised from here up.
OHM_GNOME_MIN=47
OHM_GNOME_TARGET=51

_family_from_ids() {
  local ids=" $* "
  case "${ids}" in
    *" nixos "*)                                   echo nixos ;;
    *" debian "*|*" ubuntu "*)                     echo debian ;;
    *" fedora "*|*" rhel "*|*" centos "*)          echo fedora ;;
    *" arch "*|*" archlinux "*)                    echo arch ;;
    *" suse "*|*" opensuse "*|*" sles "*)          echo suse ;;
    *" void "*)                                    echo void ;;
    *" alpine "*|*" postmarketos "*)               echo alpine ;;
    *" gentoo "*|*" funtoo "*)                     echo gentoo ;;
    *" solus "*)                                   echo solus ;;
    *)                                             echo unknown ;;
  esac
}

detect_distro() {
  local os_release=/etc/os-release
  [[ -r "${os_release}" ]] || os_release=/usr/lib/os-release

  # os-release defines generic names (VARIANT, VERSION, NAME…) that would
  # clobber the installer's own variables, so read it in a subshell and
  # import only the fields we need.
  local ID="" ID_LIKE="" PRETTY_NAME="" NAME=""
  if [[ -r "${os_release}" ]]; then
    {
      IFS= read -r ID
      IFS= read -r ID_LIKE
      IFS= read -r PRETTY_NAME
      IFS= read -r NAME
    } < <(
      # shellcheck disable=SC1090
      . "${os_release}" >/dev/null 2>&1
      printf '%s\n' "${ID:-}" "${ID_LIKE:-}" "${PRETTY_NAME:-}" "${NAME:-}"
    )
  fi
  OHM_DISTRO_ID="${OHM_FORCE_DISTRO:-${ID:-unknown}}"
  OHM_DISTRO_NAME="${PRETTY_NAME:-${NAME:-${OHM_DISTRO_ID}}}"
  # shellcheck disable=SC2086  # ID_LIKE is a space-separated list
  OHM_DISTRO_FAMILY="$(_family_from_ids "${OHM_DISTRO_ID}" ${ID_LIKE:-})"

  # Image-based systems: Silverblue/Kinoite/Bluefin/Aurora (rpm-ostree),
  # Endless, Vanilla OS, openSUSE Aeon/MicroOS… — /usr is read-only.
  if [[ -e /run/ostree-booted ]] || has transactional-update || [[ "${OHM_DISTRO_ID}" == vanilla ]]; then
    OHM_IMMUTABLE=1
  fi

  if [[ "${OHM_IMMUTABLE}" == 1 ]]; then
    if has rpm-ostree; then OHM_PKG=rpm-ostree; else OHM_PKG=""; fi
  else
    case "${OHM_DISTRO_FAMILY}" in
      debian) OHM_PKG=apt ;;
      fedora) OHM_PKG=dnf ;;
      arch)   OHM_PKG=pacman ;;
      suse)   OHM_PKG=zypper ;;
      void)   OHM_PKG=xbps ;;
      alpine) OHM_PKG=apk ;;
      gentoo) OHM_PKG=emerge ;;
      solus)  OHM_PKG=eopkg ;;
      nixos)  OHM_PKG=nix ;;
      *)
        local pm
        for pm in apt-get dnf pacman zypper xbps-install apk emerge eopkg; do
          if has "${pm}"; then
            case "${pm}" in
              apt-get) OHM_PKG=apt ;;
              xbps-install) OHM_PKG=xbps ;;
              *) OHM_PKG="${pm}" ;;
            esac
            break
          fi
        done
        ;;
    esac
  fi
}

detect_gnome() {
  if [[ -n "${OHM_FORCE_GNOME:-}" ]]; then
    OHM_GNOME_VERSION="${OHM_FORCE_GNOME}"
  elif has gnome-shell; then
    OHM_GNOME_VERSION="$(gnome-shell --version 2>/dev/null | grep -oE '[0-9]+(\.[0-9a-z]+)*' | head -n1)"
  fi
  OHM_GNOME_MAJOR="${OHM_GNOME_VERSION%%.*}"
  [[ "${OHM_GNOME_MAJOR}" =~ ^[0-9]+$ ]] || OHM_GNOME_MAJOR=0
  return 0
}

print_environment() {
  log_step "Environment"
  log_info "Distribution : ${OHM_DISTRO_NAME} (${OHM_DISTRO_FAMILY})"
  log_info "Packages     : ${OHM_PKG:-none detected}$([[ "${OHM_IMMUTABLE}" == 1 ]] && echo ' · immutable system')"
  if (( OHM_GNOME_MAJOR > 0 )); then
    log_info "GNOME Shell  : ${OHM_GNOME_VERSION}"
  else
    log_info "GNOME Shell  : not found"
  fi
  log_info "Session      : ${OHM_SESSION_TYPE}"

  if (( OHM_GNOME_MAJOR == 0 )); then
    log_warn "GNOME Shell was not found. GTK themes will be installed; Shell parts are skipped."
  elif (( OHM_GNOME_MAJOR < OHM_GNOME_MIN )); then
    log_warn "GNOME ${OHM_GNOME_MAJOR} is older than the supported minimum (${OHM_GNOME_MIN}). The Shell theme may look off."
  elif (( OHM_GNOME_MAJOR > OHM_GNOME_TARGET )); then
    log_warn "GNOME ${OHM_GNOME_MAJOR} is newer than the tested release (${OHM_GNOME_TARGET}). Please report issues."
  fi
  if [[ "${OHM_SESSION_TYPE}" == x11 ]]; then
    log_warn "X11 session detected. GNOME 50+ is Wayland-only; some effects need Wayland."
  fi
}
