#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
#
# OhMyMac test suite: unit tests for the shell libraries, a full Sass build,
# and install/uninstall round-trips inside a throw-away $HOME.

set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/loader.sh
. "${ROOT}/lib/loader.sh"

PASS=0 FAIL=0
ok()   { PASS=$((PASS + 1)); printf '  ok   %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf '  FAIL %s\n' "$1"; }
check() { local name="$1"; shift; if "$@"; then ok "${name}"; else fail "${name}"; fi; }
eq() { [[ "$1" == "$2" ]] || { printf '       expected [%s] got [%s]\n' "$2" "$1"; return 1; }; }

WORK="$(mktemp -d -t ohmymac-test.XXXXXX)"
trap 'rm -rf "${WORK}"' EXIT

echo "== distro detection"
check "ubuntu → debian"        eq "$(_family_from_ids ubuntu debian)" debian
check "linuxmint → debian"     eq "$(_family_from_ids linuxmint "ubuntu debian")" debian
check "fedora → fedora"        eq "$(_family_from_ids fedora)" fedora
check "nobara → fedora"        eq "$(_family_from_ids nobara fedora)" fedora
check "almalinux → fedora"     eq "$(_family_from_ids almalinux rhel centos fedora)" fedora
check "endeavouros → arch"     eq "$(_family_from_ids endeavouros arch)" arch
check "cachyos → arch"         eq "$(_family_from_ids cachyos arch)" arch
check "opensuse-tumbleweed"    eq "$(_family_from_ids opensuse-tumbleweed "opensuse suse")" suse
check "void"                   eq "$(_family_from_ids void)" void
check "postmarketos → alpine"  eq "$(_family_from_ids postmarketos alpine)" alpine
check "gentoo"                 eq "$(_family_from_ids gentoo)" gentoo
check "solus"                  eq "$(_family_from_ids solus)" solus
check "nixos"                  eq "$(_family_from_ids nixos)" nixos
check "unknown"                eq "$(_family_from_ids plan9)" unknown

echo "== os-release isolation (regression: Fedora's VARIANT clobbered --variant)"
FAKE_OS="$(mktemp)"
printf 'NAME="Fedora Linux"\nID=fedora\nVARIANT="Workstation Edition"\nVERSION="45"\nPRETTY_NAME="Fedora Linux 45"\n' >"${FAKE_OS}"
VARIANT=auto
os_release_test() { detect_distro_from "${FAKE_OS}"; [[ "${VARIANT}" == auto && "${OHM_DISTRO_FAMILY}" == fedora && "${OHM_DISTRO_NAME}" == "Fedora Linux 45" ]]; }
detect_distro_from() { local f="$1"; eval "$(declare -f detect_distro | sed "s|/etc/os-release|${f}|")"; detect_distro; }
check "os-release does not leak variables" os_release_test
rm -f "${FAKE_OS}"

echo "== package names"
for fam in debian fedora arch suse void alpine gentoo solus; do
  OHM_DISTRO_FAMILY="${fam}"
  check "sass package for ${fam}" test -n "$(pkg_name sass)"
done
OHM_DISTRO_FAMILY=arch
check "arch uses dart-sass" eq "$(pkg_name sass)" dart-sass

echo "== helpers"
check "version_ge 51.1 47"   version_ge 51.1 47
not() { ! "$@"; }
check "!version_ge 46 47"    not version_ge 46 47
check "list add"     eq "$(gvariant_list_edit add "['a@x', 'b@y']" 'c@z')" "['a@x','b@y','c@z']"
check "list add dup" eq "$(gvariant_list_edit add "['a@x', 'b@y']" 'a@x')" "['b@y','a@x']"
check "list remove"  eq "$(gvariant_list_edit remove "['a@x', 'b@y']" 'a@x')" "['b@y']"
check "list empty"   eq "$(gvariant_list_edit add "@as []" 'a@x')" "['a@x']"
# shellcheck disable=SC2034  # read indirectly by _expand_placeholders
OHM_TEST_NAME="Inter"
check "placeholder"  eq "$(_expand_placeholders "x '@TEST_NAME@ 11'")" "x 'Inter 11'"

echo "== extension profiles"
has_line() { grep -qxF "$1" <<<"$2"; }
check "minimal has user-theme" has_line $'user-theme@gnome-shell-extensions.gcampax.github.com\t' "$(extension_list minimal)"
lg_line="$(extension_list recommended | grep '^liquid-glass@')"
check "liquid glass has a pinned git source" grep -qE $'\tgit:https://[^@]+\\.git@[0-9a-f]{40}$' <<<"${lg_line}"
full_count="$(extension_list full | awk -F '\t' '!seen[$1]++' | wc -l)"
check "full includes recommended+minimal (${full_count})" test "${full_count}" -ge 10

echo "== sass build"
OHM_BUILD="${WORK}/build"
build_themes "${OHM_BUILD}" >/dev/null
for v in Light Dark; do
  for f in index.theme gtk-3.0/gtk.css gtk-3.0/gtk-dark.css gtk-4.0/gtk.css gtk-4.0/gtk-dark.css gnome-shell/gnome-shell.css; do
    check "${v}/${f}" test -s "${OHM_BUILD}/OhMyMac-${v}/${f}"
  done
done
check "libadwaita css"           test -s "${OHM_BUILD}/libadwaita/gtk.css"
check "gtk3 imports Adwaita"     grep -q 'gtk-contained.css' "${OHM_BUILD}/OhMyMac-Light/gtk-3.0/gtk.css"
check "gtk3 dark imports dark"   grep -q 'gtk-contained-dark.css' "${OHM_BUILD}/OhMyMac-Dark/gtk-3.0/gtk.css"
check "gtk4 has dark tokens"     grep -q 'prefers-color-scheme: dark' "${OHM_BUILD}/libadwaita/gtk.css"
check "gtk4 sets accent palette" grep -q -- '--accent-blue: #007aff' "${OHM_BUILD}/libadwaita/gtk.css"
no_match() { ! grep -rqE "$1" "$2"; }
check "no sass leftovers"         no_match '\$[a-z-]+|#\{' "${OHM_BUILD}"
check "no color keywords in vars" no_match ':[[:space:]]*(white|black);' "${OHM_BUILD}/libadwaita/gtk.css"

echo "== shell finalize"
cp -a "${OHM_BUILD}/OhMyMac-Dark" "${WORK}/shell-test"
OHM_SHELL_GRESOURCE=/nonexistent OHM_GNOME_MAJOR=51 shell_finalize "${WORK}/shell-test" Dark
check "modern base import" grep -q 'gnome-shell-dark.css' "${WORK}/shell-test/gnome-shell/gnome-shell.css"
first_rule() { grep -v '^/\*' "$1" | head -n1 | grep -q '^@import'; }
check "import is first rule" first_rule "${WORK}/shell-test/gnome-shell/gnome-shell.css"
cp -a "${OHM_BUILD}/OhMyMac-Dark" "${WORK}/shell-old"
OHM_SHELL_GRESOURCE=/nonexistent OHM_GNOME_MAJOR=46 shell_finalize "${WORK}/shell-old" Dark
check "legacy base import" grep -q 'theme/gnome-shell.css' "${WORK}/shell-old/gnome-shell/gnome-shell.css"
cp -a "${OHM_BUILD}/OhMyMac-Light" "${WORK}/shell-51-light"
OHM_SHELL_GRESOURCE=/nonexistent OHM_GNOME_MAJOR=51 shell_finalize "${WORK}/shell-51-light" Light
check "GNOME 51 light uses the light base" grep -q 'theme/gnome-shell-light.css' "${WORK}/shell-51-light/gnome-shell/gnome-shell.css"
# A bundle without a light stylesheet falls back to the dark one.
fake_gresource_dir="${WORK}/fake-gres"
mkdir -p "${fake_gresource_dir}/src"
echo '#panel{}' >"${fake_gresource_dir}/src/gnome-shell-dark.css"
printf '<gresources><gresource prefix="/org/gnome/shell/theme"><file>gnome-shell-dark.css</file></gresource></gresources>' >"${fake_gresource_dir}/t.xml"
if has glib-compile-resources && has gresource &&
   glib-compile-resources --sourcedir="${fake_gresource_dir}/src" --target="${fake_gresource_dir}/t.gresource" "${fake_gresource_dir}/t.xml"; then
  check "missing light stylesheet falls back to dark" eq "$(OHM_SHELL_GRESOURCE="${fake_gresource_dir}/t.gresource" shell_base_resource Light)" "resource:///org/gnome/shell/theme/gnome-shell-dark.css"
fi

echo "== set -e safety (regression: failing enable aborted the installer)"
# shellcheck disable=SC2329  # the stubs are called indirectly by extension_enable
enable_test() { ( set -e; has() { [[ "$1" == gnome-extensions ]]; }; gnome-extensions() { return 2; }; gsettings() { return 1; }; extension_enable foo@bar; echo survived ); }
check "extension_enable survives a failing gnome-extensions" has_line survived "$(enable_test 2>/dev/null)"

echo "== install / uninstall round-trip (isolated HOME)"
FAKE_HOME="${WORK}/home"
mkdir -p "${FAKE_HOME}/.config/gtk-4.0"
echo "/* user css */" >"${FAKE_HOME}/.config/gtk-4.0/gtk.css"
run_iso() {
  env -i HOME="${FAKE_HOME}" PATH="${PATH}" USER=tester TERM=dumb NO_COLOR=1 \
    OHM_BUILD="${OHM_BUILD}" OHM_REBUILD=0 OHM_ALLOW_ROOT=1 "$@"
}
inst_flags=(--no-deps --no-icons --no-cursors --no-fonts --no-extensions --no-flatpak --no-settings -y)

check "dry run changes nothing" bash -c "$(declare -f run_iso); FAKE_HOME='${FAKE_HOME}' OHM_BUILD='${OHM_BUILD}' PATH='${PATH}';
  run_iso '${ROOT}/install.sh' --dry-run ${inst_flags[*]} >/dev/null && [[ ! -e '${FAKE_HOME}/.local/share/themes' ]]"
check "install succeeds" bash -c "$(declare -f run_iso); FAKE_HOME='${FAKE_HOME}' OHM_BUILD='${OHM_BUILD}' PATH='${PATH}';
  run_iso '${ROOT}/install.sh' ${inst_flags[*]} >'${WORK}/install.log' 2>&1" || cat "${WORK}/install.log"
check "themes installed"      test -f "${FAKE_HOME}/.local/share/themes/OhMyMac-Dark/gnome-shell/gnome-shell.css"
check "flatpak symlink"       test -L "${FAKE_HOME}/.themes/OhMyMac-Light"
check "libadwaita css"        grep -q OhMyMac "${FAKE_HOME}/.config/gtk-4.0/gtk.css"
check "user css backed up"    test -f "${FAKE_HOME}/.local/state/ohmymac/backup${FAKE_HOME}/.config/gtk-4.0/gtk.css"
check "wallpapers installed"  test -f "${FAKE_HOME}/.local/share/backgrounds/ohmymac/ohmymac-dark.svg"
check "sync helper installed" test -x "${FAKE_HOME}/.local/bin/ohmymac-sync"
check "manifest written"      test -s "${FAKE_HOME}/.local/state/ohmymac/manifest"

check "uninstall succeeds" bash -c "$(declare -f run_iso); FAKE_HOME='${FAKE_HOME}' OHM_BUILD='${OHM_BUILD}' PATH='${PATH}';
  run_iso '${ROOT}/uninstall.sh' -y >'${WORK}/uninstall.log' 2>&1" || cat "${WORK}/uninstall.log"
check "themes removed"        test ! -e "${FAKE_HOME}/.local/share/themes/OhMyMac-Dark"
check "symlink removed"       test ! -e "${FAKE_HOME}/.themes/OhMyMac-Light"
check "user css restored"     grep -q 'user css' "${FAKE_HOME}/.config/gtk-4.0/gtk.css"
check "state cleaned"         test ! -e "${FAKE_HOME}/.local/state/ohmymac"

echo "== packaging (make install DESTDIR)"
quiet() { "$@" >/dev/null; }
check "make install" quiet make -s -C "${ROOT}" install BUILD="${OHM_BUILD}" DESTDIR="${WORK}/pkg"
check "staged shell theme has import" grep -q '^@import' "${WORK}/pkg/usr/share/themes/OhMyMac-Light/gnome-shell/gnome-shell.css"

echo
echo "passed: ${PASS}  failed: ${FAIL}"
((FAIL == 0))
