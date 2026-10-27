#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# Generates the login screen background shipped in the GDM bundle:
#   rsvg-convert -w 1920 -h 1080 src/wallpapers/ohmymac-dark.svg -o /tmp/wd.png
#   python3 tools/gen-login-background.py /tmp/wd.png src/gdm/login-background.jpg
# Like macOS Tahoe, the login window shows the wallpaper itself, sharp and
# only slightly dimmed so the clock and the user stay legible.
import sys

from PIL import Image, ImageEnhance

src, out = sys.argv[1], sys.argv[2]
img = Image.open(src).convert("RGB").resize((1920, 1080), Image.LANCZOS)
img = ImageEnhance.Brightness(img).enhance(0.88)
img.save(out, "JPEG", quality=90, optimize=True, progressive=True)
