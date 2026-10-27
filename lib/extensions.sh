# shellcheck shell=bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# OhMyMac — GNOME Shell extensions, installed from extensions.gnome.org for
# the exact Shell version that is running. Nothing is vendored: every
# extension comes from its reviewed upstream release.

OHM_EGO="${OHM_EGO:-https://extensions.gnome.org}"
OHM_USER_EXT_DIR="${XDG_DATA_HOME}/gnome-shell/extensions"
OHM_SYSTEM_EXT_DIRS=(/usr/share/gnome-shell/extensions /usr/local/share/gnome-shell/extensions)

# Extensions that fight with ones OhMyMac installs: "ours=theirs".
OHM_EXT_CONFLICTS=(
  "dash-to-dock@micxgx.gmail.com=ubuntu-dock@ubuntu.com"
  "dash-to-dock@micxgx.gmail.com=dash-to-panel@jderose9.github.com"
  "appindicatorsupport@rgcjonas.gmail.com=ubuntu-appindicators@ubuntu.com"
)

# Reads data/extensions/<profile>.list (comments and blank lines ignored).
# Profiles include their parents through "@include <profile>" lines.
extension_list() {
  local profile="$1" file="${OHM_ROOT}/data/extensions/$1.list" line
  [[ -r "${file}" ]] || die "Unknown extension profile: ${profile}"
  while IFS= read -r line || [[ -n "${line}" ]]; do
    line="${line%%#*}"
    line="${line//[[:space:]]/}"
    [[ -z "${line}" ]] && continue
    if [[ "${line}" == @include* ]]; then
      extension_list "${line#@include}"
    else
      printf '%s\n' "${line}"
    fi
  done <"${file}"
}

extension_path() {
  local uuid="$1" dir
  for dir in "${OHM_USER_EXT_DIR}" "${OHM_SYSTEM_EXT_DIRS[@]}"; do
    [[ -f "${dir}/${uuid}/metadata.json" ]] && { echo "${dir}/${uuid}"; return 0; }
  done
  return 1
}

# Schema directory for an extension's GSettings, or "" if the schema is
# globally installed (distribution packages).
extension_schemadir() {
  local path
  path="$(extension_path "$1")" || return 0
  [[ -d "${path}/schemas" ]] && echo "${path}/schemas"
  return 0
}

# --- org.gnome.shell list helpers ----------------------------------------------

# gvariant_list_edit <add|remove> <current-gvariant-list> <item>
gvariant_list_edit() {
  local op="$1" current="$2" item="$3" body
  body="${current#@as }"
  body="${body#[}"
  body="${body%]}"
  local -a items=() out=()
  local entry
  IFS=',' read -r -a items <<<"${body}"
  for entry in "${items[@]}"; do
    entry="${entry#"${entry%%[![:space:]]*}"}"
    entry="${entry%"${entry##*[![:space:]]}"}"
    entry="${entry#\'}"
    entry="${entry%\'}"
    [[ -z "${entry}" || "${entry}" == "${item}" ]] && continue
    out+=("'${entry}'")
  done
  [[ "${op}" == add ]] && out+=("'${item}'")
  local IFS=','
  printf '[%s]\n' "${out[*]}"
}

shell_list_set() {
  local key="$1" op="$2" item="$3" current
  has gsettings || return 0
  current="$(gsettings get org.gnome.shell "${key}" 2>/dev/null)" || return 0
  [[ -n "${current}" ]] || return 0
  run gsettings set org.gnome.shell "${key}" "$(gvariant_list_edit "${op}" "${current}" "${item}")"
}

extension_enable() {
  local uuid="$1"
  shell_list_set disabled-extensions remove "${uuid}"
  shell_list_set enabled-extensions add "${uuid}"
  # Takes effect immediately when the Shell already knows the extension;
  # freshly installed ones load at next login (Wayland cannot restart).
  has gnome-extensions && run gnome-extensions enable "${uuid}" >/dev/null 2>&1
  return 0
}

extension_disable() {
  local uuid="$1"
  shell_list_set enabled-extensions remove "${uuid}"
  has gnome-extensions && run gnome-extensions disable "${uuid}" >/dev/null 2>&1
  return 0
}

# --- Download & install ----------------------------------------------------------

# Prints the download path for an extension compatible with this Shell.
ego_download_path() {
  local uuid="$1" major="$2" info
  info="$(fetch_stdout "${OHM_EGO}/extension-info/?uuid=${uuid}&shell_version=${major}" 2>/dev/null)" || return 2
  # Strict compatibility: the extension must list this Shell major version.
  if [[ "${OHM_EXT_ALLOW_INCOMPATIBLE:-0}" != 1 ]] &&
     ! grep -qE "\"${major}(\.[0-9a-z]+)?\": *\{" <<<"${info}"; then
    return 3
  fi
  grep -oE '"download_url": *"[^"]+"' <<<"${info}" | head -n1 | sed -E 's/.*"download_url": *"([^"]+)"/\1/'
}

extension_install_zip() {
  local zip="$1" uuid="$2"
  if has gnome-extensions && [[ "${OHM_DRY_RUN}" != 1 ]] &&
     gnome-extensions install --force "${zip}" >/dev/null 2>&1; then
    return 0
  fi
  # Fallback without gnome-extensions (or outside a session).
  local dest="${OHM_USER_EXT_DIR}/${uuid}"
  run rm -rf "${dest}"
  run mkdir -p "${dest}"
  run unzip -qo "${zip}" -d "${dest}"
  if [[ -d "${dest}/schemas" ]] && has glib-compile-schemas; then
    run glib-compile-schemas "${dest}/schemas"
  fi
}

install_extension() {
  local uuid="$1" major="${OHM_GNOME_MAJOR}" path url zip rc

  if path="$(extension_path "${uuid}")" && [[ "${OHM_EXT_UPDATE:-0}" != 1 ]]; then
    log_ok "${uuid} (already installed)"
  else
    rc=0
    url="$(ego_download_path "${uuid}" "${major}")" || rc=$?
    case "${rc}" in
      0) ;;
      3) log_warn "${uuid}: no release for GNOME ${major} yet — skipped (use --allow-incompatible to force)"; return 0 ;;
      *) log_warn "${uuid}: extensions.gnome.org unreachable — skipped"; return 0 ;;
    esac
    [[ -n "${url}" ]] || { log_warn "${uuid}: no download URL — skipped"; return 0; }

    zip="${OHM_TMP}/${uuid}.zip"
    fetch "${OHM_EGO}${url}" "${zip}" || { log_warn "${uuid}: download failed — skipped"; return 0; }
    extension_install_zip "${zip}" "${uuid}"
    manifest_add "extension:${uuid}"
    log_ok "${uuid}"
  fi

  local pair
  for pair in "${OHM_EXT_CONFLICTS[@]}"; do
    if [[ "${pair%%=*}" == "${uuid}" ]]; then
      shell_list_set enabled-extensions remove "${pair#*=}"
      shell_list_set disabled-extensions add "${pair#*=}"
    fi
  done
  extension_enable "${uuid}"
}

install_extensions() {
  local profile="${1:-recommended}" uuid
  if (( OHM_GNOME_MAJOR == 0 )); then
    log_warn "GNOME Shell not found; skipping extensions."
    return 0
  fi
  log_step "Extensions (${profile}) for GNOME ${OHM_GNOME_MAJOR}"
  install_deps unzip
  if has gsettings; then
    _backup_setting "" org.gnome.shell enabled-extensions
    _backup_setting "" org.gnome.shell disabled-extensions
  fi
  while IFS= read -r uuid; do
    install_extension "${uuid}"
  done < <(extension_list "${profile}" | awk '!seen[$0]++')

  # Shell must allow user extensions at all.
  set_setting org.gnome.shell disable-user-extensions false
}
