# shellcheck shell=bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# OhMyMac — optional login screen (GDM) styling.
#
# GDM runs its own Shell that reads the theme from a GResource bundle, not
# from user themes. OhMyMac rebuilds that bundle: the stock stylesheets are
# kept (renamed *-stock.css) and new ones @import them before adding the
# OhMyMac rules, exactly like the user theme does. The original bundle is
# backed up and restored by `uninstall.sh --gdm`. The bundle also carries
# the blurred wallpaper the login screen is drawn on, like macOS.
#
# Distribution updates of gnome-shell replace the bundle; re-run
# `install.sh --gdm` afterwards.

OHM_GDM_DIR="/usr/share/gnome-shell"
OHM_GDM_RESOURCE="${OHM_GDM_DIR}/gnome-shell-theme.gresource"
OHM_GDM_OURS="${OHM_GDM_DIR}/ohmymac-gdm.gresource"
OHM_GDM_BACKUP="${OHM_GDM_RESOURCE}.ohmymac-backup"
OHM_GDM_ALT="gdm-theme.gresource"   # Debian/Ubuntu alternatives name

# The layout (clock at the top, user at the bottom) comes from the OhMyMac
# Lock Screen extension, installed system-wide and enabled for the greeter
# through GDM's dconf database.
OHM_GDM_EXT_UUID="ohmymac-lockscreen@cmpdchtr.github.io"
OHM_GDM_EXT_DIR="/usr/share/gnome-shell/extensions/${OHM_GDM_EXT_UUID}"
OHM_GDM_DCONF_DB="/etc/dconf/db/gdm.d"
OHM_GDM_DCONF_FILE="${OHM_GDM_DCONF_DB}/90-ohmymac"
OHM_GDM_PROFILE="/etc/dconf/profile/gdm"
OHM_GDM_PROFILE_MARK="/etc/dconf/profile/.gdm-created-by-ohmymac"

_gdm_uses_alternatives() {
  has update-alternatives && update-alternatives --query "${OHM_GDM_ALT}" >/dev/null 2>&1
}

_gdm_is_ours() {
  grep -q -- '-stock\.css$' <<<"$(gresource list "$1" 2>/dev/null)"
}

_gdm_source_resource() {
  local current
  if _gdm_uses_alternatives; then
    current="$(readlink -f "${OHM_GDM_DIR}/gdm-theme.gresource")"
    # Never stack on top of ourselves: fall back to the stock Shell bundle.
    _gdm_is_ours "${current}" && current="$(readlink -f "${OHM_GDM_RESOURCE}")"
    echo "${current}"
  elif _gdm_is_ours "${OHM_GDM_RESOURCE}" && [[ -f "${OHM_GDM_BACKUP}" ]]; then
    echo "${OHM_GDM_BACKUP}"
  else
    # Fresh stock bundle (first run, or gnome-shell was updated).
    readlink -f "${OHM_GDM_RESOURCE}"
  fi
}

# Only the greeter gets the picture: in a user session the lock screen
# already shows the user's own wallpaper, blurred by the Shell.
_gdm_background_css() {
  cat <<'EOF'

#lockDialogGroup {
  background: #061a52 url("resource:///org/gnome/shell/theme/ohmymac-login.jpg");
  background-size: cover;
}
EOF
}

# _gdm_build <source.gresource> <out.gresource>
_gdm_build() {
  local src="$1" out="$2" work="${OHM_TMP}/gdm" prefix="/org/gnome/shell/theme" file rel variant css
  rm -rf "${work}"
  mkdir -p "${work}"

  while IFS= read -r file; do
    rel="${file#"${prefix}"/}"
    mkdir -p "${work}/$(dirname "${rel}")"
    gresource extract "${src}" "${file}" >"${work}/${rel}"
  done < <(gresource list "${src}")
  cp -f "${OHM_SRC}/gdm/login-background.jpg" "${work}/ohmymac-login.jpg"

  for variant in light dark; do
    css="gnome-shell-${variant}.css"
    [[ -f "${work}/${css}" ]] || continue
    [[ -f "${work}/gnome-shell-${variant}-stock.css" ]] ||
      mv "${work}/${css}" "${work}/gnome-shell-${variant}-stock.css"
    {
      printf '/* OhMyMac %s — login screen */\n' "${OHM_VERSION}"
      printf '@import url("resource://%s/gnome-shell-%s-stock.css");\n\n' "${prefix}" "${variant}"
      cat "${OHM_BUILD}/OhMyMac-${variant^}/gnome-shell/gnome-shell.css"
      _gdm_background_css
    } >"${work}/${css}"
  done

  # Pre-47 Shells have a single gnome-shell.css.
  if [[ -f "${work}/gnome-shell.css" && ! -f "${work}/gnome-shell-dark.css" ]]; then
    mv "${work}/gnome-shell.css" "${work}/gnome-shell-stock.css"
    {
      printf '@import url("resource://%s/gnome-shell-stock.css");\n\n' "${prefix}"
      cat "${OHM_BUILD}/OhMyMac-Dark/gnome-shell/gnome-shell.css"
      _gdm_background_css
    } >"${work}/gnome-shell.css"
  fi

  {
    printf '<?xml version="1.0" encoding="UTF-8"?>\n<gresources>\n  <gresource prefix="%s">\n' "${prefix}"
    (cd "${work}" && find . -type f ! -name '*.xml' -printf '    <file>%P</file>\n' | sort)
    printf '  </gresource>\n</gresources>\n'
  } >"${work}/ohmymac.gresource.xml"

  glib-compile-resources --sourcedir="${work}" --target="${out}" "${work}/ohmymac.gresource.xml"
}

# The greeter's dconf profile must read the "gdm" system database.
_gdm_profile_ok() {
  local profile
  for profile in "${OHM_GDM_PROFILE}" /usr/share/dconf/profile/gdm; do
    [[ -r "${profile}" ]] || continue
    grep -qx 'system-db:gdm' "${profile}" && return 0
    return 1
  done
  return 2
}

_gdm_install_extension() {
  has dconf || { log_warn "dconf is missing: the login screen keeps the stock layout."; return 0; }
  local rc=0
  _gdm_profile_ok || rc=$?
  if ((rc == 2)); then
    run_root install -Dm644 /dev/stdin "${OHM_GDM_PROFILE}" \
      <<<$'user-db:user\nsystem-db:gdm\nfile-db:/usr/share/gdm/greeter-dconf-defaults'
    run_root touch "${OHM_GDM_PROFILE_MARK}"
  elif ((rc == 1)); then
    log_warn "GDM's dconf profile has no system-db:gdm: the login screen keeps the stock layout."
    return 0
  fi
  run_root rm -rf "${OHM_GDM_EXT_DIR}"
  run_root mkdir -p "$(dirname "${OHM_GDM_EXT_DIR}")"
  run_root cp -r "${OHM_ROOT}/extensions/${OHM_GDM_EXT_UUID}" "${OHM_GDM_EXT_DIR}"
  run_root chmod -R a+rX "${OHM_GDM_EXT_DIR}"
  run_root install -Dm644 /dev/stdin "${OHM_GDM_DCONF_FILE}" \
    <<<$'# OhMyMac: macOS layout for the login screen\n[org/gnome/shell]\nenabled-extensions=[\''"${OHM_GDM_EXT_UUID}"$'\']'
  run_root dconf update
  log_ok "Login screen layout (clock at the top, user at the bottom)"
}

_gdm_uninstall_extension() {
  local changed=0
  [[ -d "${OHM_GDM_EXT_DIR}" ]] && { run_root rm -rf "${OHM_GDM_EXT_DIR}"; changed=1; }
  [[ -f "${OHM_GDM_DCONF_FILE}" ]] && { run_root rm -f "${OHM_GDM_DCONF_FILE}"; changed=1; }
  if [[ -f "${OHM_GDM_PROFILE_MARK}" ]]; then
    run_root rm -f "${OHM_GDM_PROFILE}" "${OHM_GDM_PROFILE_MARK}"
    changed=1
  fi
  if ((changed)); then
    has dconf && run_root dconf update
    log_ok "Login screen layout removed"
  fi
  return 0
}

install_gdm() {
  log_step "Login screen (GDM)"
  if [[ "${OHM_IMMUTABLE}" == 1 ]]; then
    log_warn "Immutable system: /usr is read-only, the login screen cannot be themed."
    return 0
  fi
  [[ -e "${OHM_GDM_RESOURCE}" ]] || { log_warn "No ${OHM_GDM_RESOURCE}; skipping."; return 0; }
  require gresource glib-compile-resources
  [[ -d "${OHM_BUILD}/OhMyMac-Dark" ]] || build_themes

  local src built="${OHM_TMP}/ohmymac-gdm.gresource"
  src="$(_gdm_source_resource)"
  log_info "Base bundle: ${src}"
  if [[ "${OHM_DRY_RUN}" == 1 ]]; then
    log_info "[dry-run] would rebuild ${OHM_GDM_RESOURCE}"
    return 0
  fi
  _gdm_build "${src}" "${built}" || die "Failed to build the GDM theme bundle."

  if _gdm_uses_alternatives; then
    run_root install -Dm644 "${built}" "${OHM_GDM_OURS}"
    run_root update-alternatives --install "${OHM_GDM_DIR}/gdm-theme.gresource" \
      "${OHM_GDM_ALT}" "${OHM_GDM_OURS}" 100
    run_root update-alternatives --set "${OHM_GDM_ALT}" "${OHM_GDM_OURS}"
  else
    _gdm_is_ours "${OHM_GDM_RESOURCE}" ||
      run_root cp -a "$(readlink -f "${OHM_GDM_RESOURCE}")" "${OHM_GDM_BACKUP}"
    run_root install -Dm644 "${built}" "${OHM_GDM_RESOURCE}"
  fi
  log_ok "Login screen styled (visible after logout or reboot)"
  _gdm_install_extension
}

uninstall_gdm() {
  log_step "Restoring the stock login screen"
  if _gdm_uses_alternatives && [[ -f "${OHM_GDM_OURS}" ]]; then
    run_root update-alternatives --remove "${OHM_GDM_ALT}" "${OHM_GDM_OURS}"
    run_root rm -f "${OHM_GDM_OURS}"
    log_ok "Alternative removed"
  elif [[ -f "${OHM_GDM_BACKUP}" ]]; then
    run_root mv -f "${OHM_GDM_BACKUP}" "${OHM_GDM_RESOURCE}"
    log_ok "Original bundle restored"
  else
    log_info "OhMyMac login theme is not installed."
  fi
  _gdm_uninstall_extension
}
