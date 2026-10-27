# shellcheck shell=bash disable=SC2034  # variables are consumed by sourcing scripts
# SPDX-License-Identifier: GPL-3.0-or-later
#
# OhMyMac — shared helpers: logging, dry-run aware execution, downloads,
# install manifest and state directories. Sourced by install.sh/uninstall.sh.

OHM_NAME="OhMyMac"
OHM_VERSION="$(cat "${OHM_ROOT}/VERSION" 2>/dev/null || echo "0.0.0")"

: "${XDG_CONFIG_HOME:=${HOME}/.config}"
: "${XDG_DATA_HOME:=${HOME}/.local/share}"
: "${XDG_STATE_HOME:=${HOME}/.local/state}"
: "${XDG_CACHE_HOME:=${HOME}/.cache}"

OHM_STATE_DIR="${XDG_STATE_HOME}/ohmymac"
OHM_CACHE_DIR="${XDG_CACHE_HOME}/ohmymac"
OHM_MANIFEST="${OHM_STATE_DIR}/manifest"
OHM_SETTINGS_BACKUP="${OHM_STATE_DIR}/gsettings.backup"
OHM_BACKUP_DIR="${OHM_STATE_DIR}/backup"

OHM_DRY_RUN="${OHM_DRY_RUN:-0}"
OHM_ASSUME_YES="${OHM_ASSUME_YES:-0}"
OHM_VERBOSE="${OHM_VERBOSE:-0}"

# --- Output ------------------------------------------------------------------

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  _c_reset=$'\e[0m' _c_bold=$'\e[1m' _c_dim=$'\e[2m'
  _c_red=$'\e[31m' _c_green=$'\e[32m' _c_yellow=$'\e[33m' _c_blue=$'\e[34m'
else
  _c_reset='' _c_bold='' _c_dim='' _c_red='' _c_green='' _c_yellow='' _c_blue=''
fi

log_step()  { printf '\n%s==>%s %s%s%s\n' "${_c_blue}${_c_bold}" "${_c_reset}" "${_c_bold}" "$*" "${_c_reset}"; }
log_info()  { printf '  %s•%s %s\n' "${_c_blue}" "${_c_reset}" "$*"; }
log_ok()    { printf '  %s✓%s %s\n' "${_c_green}" "${_c_reset}" "$*"; }
log_warn()  { printf '  %s!%s %s\n' "${_c_yellow}" "${_c_reset}" "$*" >&2; }
log_error() { printf '%s✗ %s%s\n' "${_c_red}${_c_bold}" "$*" "${_c_reset}" >&2; }
log_debug() { [[ "${OHM_VERBOSE}" == 1 ]] && printf '  %s%s%s\n' "${_c_dim}" "$*" "${_c_reset}"; return 0; }

die() { log_error "$*"; exit 1; }

# --- Execution ---------------------------------------------------------------

# Runs a command, or only prints it in dry-run mode.
run() {
  if [[ "${OHM_DRY_RUN}" == 1 ]]; then
    printf '  %s[dry-run]%s %s\n' "${_c_dim}" "${_c_reset}" "$*"
    return 0
  fi
  log_debug "+ $*"
  "$@"
}

# Like run(), but with root privileges (sudo, doas or run0).
run_root() {
  if [[ "${EUID}" -eq 0 ]]; then
    run "$@"
  elif [[ -n "${OHM_SUDO:-}" ]]; then
    run "${OHM_SUDO}" "$@"
  else
    die "Root privileges are required for: $* (install sudo, doas or run0)"
  fi
}

detect_sudo() {
  local tool
  for tool in sudo doas run0; do
    if command -v "${tool}" >/dev/null 2>&1; then
      OHM_SUDO="${tool}"
      return 0
    fi
  done
  OHM_SUDO=""
}

has() { command -v "$1" >/dev/null 2>&1; }

require() {
  local missing=() cmd
  for cmd in "$@"; do has "${cmd}" || missing+=("${cmd}"); done
  ((${#missing[@]} == 0)) || die "Missing required commands: ${missing[*]}"
}

confirm() {
  local prompt="$1" default="${2:-y}" reply
  [[ "${OHM_ASSUME_YES}" == 1 ]] && return 0
  [[ -t 0 ]] || { [[ "${default}" == y ]]; return; }
  if [[ "${default}" == y ]]; then prompt+=" [Y/n] "; else prompt+=" [y/N] "; fi
  read -r -p "  ${prompt}" reply || true
  reply="${reply:-${default}}"
  [[ "${reply,,}" == y || "${reply,,}" == yes || "${reply,,}" == т || "${reply,,}" == так ]]
}

# --- Version helpers ---------------------------------------------------------

# version_ge A B → true when A >= B (dotted numeric versions).
version_ge() {
  [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" == "$2" ]]
}

# --- Downloads ---------------------------------------------------------------

fetch() {
  local url="$1" out="$2"
  if has curl; then
    run curl --fail --location --silent --show-error --retry 3 --retry-delay 2 \
      --proto '=https' --tlsv1.2 -o "${out}" "${url}"
  elif has wget; then
    run wget --quiet --tries=3 --https-only -O "${out}" "${url}"
  else
    die "Neither curl nor wget is available"
  fi
}

fetch_stdout() {
  local url="$1"
  if has curl; then
    curl --fail --location --silent --show-error --retry 3 --proto '=https' "${url}"
  else
    wget --quiet --tries=3 --https-only -O - "${url}"
  fi
}

# --- Manifest of installed paths ---------------------------------------------
#
# Everything OhMyMac writes is recorded so uninstall.sh removes exactly that
# and nothing else.

manifest_add() {
  [[ "${OHM_DRY_RUN}" == 1 ]] && return 0
  mkdir -p "${OHM_STATE_DIR}"
  local path
  for path in "$@"; do
    grep -qxF "${path}" "${OHM_MANIFEST}" 2>/dev/null || printf '%s\n' "${path}" >>"${OHM_MANIFEST}"
  done
}

# Moves a pre-existing user file out of the way before OhMyMac replaces it.
backup_file() {
  local path="$1" dest
  [[ -e "${path}" || -L "${path}" ]] || return 0
  grep -q 'OhMyMac' "${path}" 2>/dev/null && return 0
  dest="${OHM_BACKUP_DIR}${path}"
  run mkdir -p "$(dirname "${dest}")"
  run mv -f "${path}" "${dest}"
  log_info "Backed up ${path/#${HOME}/\~}"
}

restore_backups() {
  [[ -d "${OHM_BACKUP_DIR}" ]] || return 0
  local file target
  while IFS= read -r -d '' file; do
    target="${file#"${OHM_BACKUP_DIR}"}"
    run mkdir -p "$(dirname "${target}")"
    run mv -f "${file}" "${target}"
    log_ok "Restored ${target/#${HOME}/\~}"
  done < <(find "${OHM_BACKUP_DIR}" -type f -print0)
}

# Creates the per-run scratch directory. Call once from the main shell, never
# inside $(...), so the cleanup trap belongs to the right process.
ohm_init_tmp() {
  OHM_TMP="$(mktemp -d -t ohmymac.XXXXXX)"
  trap 'rm -rf "${OHM_TMP}"' EXIT
}
