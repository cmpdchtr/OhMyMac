# shellcheck shell=bash disable=SC2034  # variables are consumed by sourcing scripts
# SPDX-License-Identifier: GPL-3.0-or-later
#
# OhMyMac — dependency installation across package managers.
#
# Dependencies are expressed as abstract names and mapped to real package
# names per family. A package that a distribution does not carry maps to "-"
# and is skipped. Everything here is optional except a Sass compiler, and
# that is only needed when the bundled build/ directory is absent.

# name            debian                  fedora                    arch                suse                     void              alpine          gentoo                       solus
_OHM_PKG_TABLE='
sass              sassc                   sassc                     dart-sass           sassc                    sassc             sassc           dev-lang/sassc               sassc
glib              libglib2.0-bin          glib2                     glib2               glib2-tools              glib              glib            dev-libs/glib                glib2
curl              curl                    curl                      curl                curl                     curl              curl            net-misc/curl                curl
unzip             unzip                   unzip                     unzip               unzip                    unzip             unzip           app-arch/unzip               unzip
git               git                     git                       git                 git                      git               git             dev-vcs/git                  git
xz                xz-utils                xz                        xz                  xz                       xz                xz              app-arch/xz-utils            xz
dconf             dconf-cli               dconf                     dconf               dconf                    dconf             dconf           gnome-base/dconf             dconf
font-inter        fonts-inter             rsms-inter-fonts          inter-font          google-inter-fonts       font-inter        font-inter      media-fonts/inter            font-inter
tweaks            gnome-tweaks            gnome-tweaks              gnome-tweaks        gnome-tweaks             gnome-tweaks      gnome-tweaks    gnome-extra/gnome-tweaks     gnome-tweaks
'

# Packages every run needs (cheap, present almost everywhere).
OHM_DEPS_CORE=(glib curl unzip xz)
# Needed only to build the stylesheets from source.
OHM_DEPS_BUILD=(sass)

_pkg_column() {
  case "${OHM_DISTRO_FAMILY}" in
    debian) echo 2 ;; fedora) echo 3 ;; arch) echo 4 ;; suse) echo 5 ;;
    void) echo 6 ;; alpine) echo 7 ;; gentoo) echo 8 ;; solus) echo 9 ;;
    *) echo 0 ;;
  esac
}

pkg_name() {
  local col
  col="$(_pkg_column)"
  ((col > 0)) || return 1
  awk -v n="$1" -v c="${col}" '$1 == n { print $c; found=1 } END { exit !found }' <<<"${_OHM_PKG_TABLE}"
}

# Returns true when the abstract dependency is already satisfied.
dep_satisfied() {
  case "$1" in
    sass)       has sassc || has sass ;;
    glib)       has glib-compile-resources && has gsettings ;;
    curl)       has curl || has wget ;;
    unzip)      has unzip || has bsdtar ;;
    git)        has git ;;
    xz)         has xz ;;
    dconf)      has dconf ;;
    font-inter) has fc-list && grep -qi 'Inter' <<<"$(fc-list : family 2>/dev/null)" ;;
    tweaks)     has gnome-tweaks ;;
    *)          return 1 ;;
  esac
}

pkg_install_native() {
  (($# > 0)) || return 0
  case "${OHM_PKG}" in
    apt)    run_root apt-get update -qq && run_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@" ;;
    dnf)    run_root dnf install -y "$@" ;;
    pacman) run_root pacman -S --needed --noconfirm "$@" ;;
    zypper) run_root zypper --non-interactive install --no-recommends "$@" ;;
    xbps)   run_root xbps-install -Sy "$@" ;;
    apk)    run_root apk add "$@" ;;
    emerge) run_root emerge --ask=n --noreplace "$@" ;;
    eopkg)  run_root eopkg install -y "$@" ;;
    *)      return 1 ;;
  esac
}

# install_deps <abstract-name>... — installs what is missing, never fails hard
# for optional packages.
install_deps() {
  local missing=() dep name
  for dep in "$@"; do
    dep_satisfied "${dep}" && continue
    name="$(pkg_name "${dep}" 2>/dev/null)" || name=""
    [[ -n "${name}" && "${name}" != "-" ]] && missing+=("${name}")
  done
  ((${#missing[@]} == 0)) && return 0

  case "${OHM_PKG}" in
    rpm-ostree)
      log_warn "Immutable system: layer these packages yourself if you want them:"
      log_warn "  rpm-ostree install ${missing[*]}"
      return 0 ;;
    nix)
      log_warn "NixOS: add these to environment.systemPackages: ${missing[*]}"
      return 0 ;;
    "")
      log_warn "Unknown package manager. Please install: ${missing[*]}"
      return 0 ;;
  esac

  if [[ "${OHM_NO_DEPS:-0}" == 1 ]]; then
    log_warn "Skipping packages (--no-deps): ${missing[*]}"
    return 0
  fi

  log_info "Installing packages via ${OHM_PKG}: ${missing[*]}"
  pkg_install_native "${missing[@]}" && return 0

  # One unknown name aborts the whole transaction on most package managers,
  # so fall back to installing one by one.
  local pkg failed=()
  for pkg in "${missing[@]}"; do
    pkg_install_native "${pkg}" >/dev/null 2>&1 || failed+=("${pkg}")
  done
  ((${#failed[@]} == 0)) || log_warn "Could not install: ${failed[*]} (continuing)"
}
