# shellcheck shell=bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Loads every OhMyMac library without running the installer
# (used by the Makefile and the test suite).

OHM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
set -Eeuo pipefail
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
