#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Parses built stylesheets with the real GTK CSS engine and fails on any
parsing error (unknown property, bad value, bad selector).

Usage: validate-gtk.py 3|4 FILE.css [FILE.css ...]
Needs PyGObject with GTK 3 or GTK 4 and a display (use xvfb-run in CI).
"""
import sys

import gi

version = sys.argv[1]
gi.require_version("Gtk", "3.0" if version == "3" else "4.0")
from gi.repository import GLib, Gtk  # noqa: E402

if version == "3":
    Gtk.init([])
else:
    Gtk.init()

failures = 0
for path in sys.argv[2:]:
    errors = []
    provider = Gtk.CssProvider()

    def on_error(_provider, section, error, errors=errors):
        where = section.to_string() if hasattr(section, "to_string") else ""
        errors.append(f"{where}: {error.message}")

    provider.connect("parsing-error", on_error)
    try:
        provider.load_from_path(path)
    except GLib.Error as exc:  # GTK 3 raises on the first error as well
        errors.append(exc.message)

    if errors:
        failures += 1
        print(f"FAIL {path}")
        for line in dict.fromkeys(errors):
            print(f"     {line}")
    else:
        print(f"ok   {path}")

sys.exit(1 if failures else 0)
