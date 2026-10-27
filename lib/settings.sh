# shellcheck shell=bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# OhMyMac — GSettings presets with backup/restore.
#
# Preset files (data/settings/*.conf) hold one setting per line:
#
#     schema  key  value
#
# Values may use @PLACEHOLDERS@ filled from the install context. A line is
# skipped when its schema or key does not exist on this system, so presets
# stay valid across GNOME releases and with optional extensions missing.
# The previous value of every key is saved once, before OhMyMac first
# touches it, and put back by uninstall.sh.

# _gs <schemadir|""> <gsettings args...>
_gs() {
  local dir="$1"; shift
  if [[ -n "${dir}" ]]; then gsettings --schemadir "${dir}" "$@"; else gsettings "$@"; fi
}

# Note: matches use here-strings, not pipes — with pipefail, "cmd | grep -q"
# can fail when grep exits early and cmd dies of SIGPIPE.
#
# Locates the schema directory for a schema: "" when globally installed,
# an extension's schemas/ directory otherwise. Fails when unknown.
schema_dir_for() {
  local schema="$1" dir base
  if grep -qxF "${schema}" <<<"$(gsettings list-schemas 2>/dev/null)"; then
    echo ""
    return 0
  fi
  for base in "${OHM_USER_EXT_DIR}" "${OHM_SYSTEM_EXT_DIRS[@]}"; do
    for dir in "${base}"/*/schemas; do
      [[ -f "${dir}/gschemas.compiled" ]] || continue
      if grep -qxF "${schema}" <<<"$(gsettings --schemadir "${dir}" list-schemas 2>/dev/null)"; then
        echo "${dir}"
        return 0
      fi
    done
  done
  return 1
}

_backup_setting() {
  local dir="$1" schema="$2" key="$3" value
  [[ "${OHM_DRY_RUN}" == 1 ]] && return 0
  mkdir -p "${OHM_STATE_DIR}"
  grep -qF "${schema}	${key}	" "${OHM_SETTINGS_BACKUP}" 2>/dev/null && return 0
  value="$(_gs "${dir}" get "${schema}" "${key}" 2>/dev/null)" || return 0
  printf '%s\t%s\t%s\t%s\n' "${schema}" "${key}" "${value}" "${dir}" >>"${OHM_SETTINGS_BACKUP}"
}

# set_setting <schema> <key> <value>
set_setting() {
  local schema="$1" key="$2" value="$3" dir
  dir="$(schema_dir_for "${schema}")" || { log_debug "skip ${schema} (not installed)"; return 0; }
  if ! grep -qxF "${key}" <<<"$(_gs "${dir}" list-keys "${schema}" 2>/dev/null)"; then
    log_debug "skip ${schema} ${key} (unknown key)"
    return 0
  fi
  _backup_setting "${dir}" "${schema}" "${key}"
  run _gs "${dir}" set "${schema}" "${key}" "${value}" ||
    log_warn "Could not set ${schema} ${key}"
}

_expand_placeholders() {
  local line="$1" name value
  while [[ "${line}" =~ @([A-Z_]+)@ ]]; do
    name="${BASH_REMATCH[1]}"
    value="OHM_${name}"
    line="${line//@${name}@/${!value:-}}"
  done
  printf '%s' "${line}"
}

apply_preset() {
  local file="${OHM_ROOT}/data/settings/$1.conf" line schema key value
  [[ -r "${file}" ]] || die "Unknown settings preset: $1"
  has gsettings || { log_warn "gsettings not found; skipping $1 settings."; return 0; }

  while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ "${line}" =~ ^[[:space:]]*(#|$) ]] && continue
    line="$(_expand_placeholders "${line}")"
    read -r schema key value <<<"${line}"
    [[ -n "${schema}" && -n "${key}" && -n "${value}" ]] || continue
    set_setting "${schema}" "${key}" "${value}"
  done <"${file}"
  log_ok "Applied preset: $1"
}

restore_settings() {
  [[ -r "${OHM_SETTINGS_BACKUP}" ]] || { log_info "No saved settings to restore."; return 0; }
  has gsettings || return 0
  local schema key value dir
  while IFS=$'\t' read -r schema key value dir; do
    if [[ -n "${dir}" && ! -d "${dir}" ]]; then
      continue
    fi
    run _gs "${dir}" set "${schema}" "${key}" "${value}" 2>/dev/null ||
      log_debug "could not restore ${schema} ${key}"
  done <"${OHM_SETTINGS_BACKUP}"
  log_ok "Previous GNOME settings restored"
}
