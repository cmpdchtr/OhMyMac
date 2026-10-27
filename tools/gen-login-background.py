#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# Generates the blurred login-screen background shipped in the GDM bundle:
#   rsvg-convert -w 1920 -h 1080 src/wallpapers/ohmymac-dark.svg -o /tmp/wd.png
#   python3 tools/gen-login-background.py /tmp/wd.png src/gdm/login-background.jpg
# Like macOS, the login screen shows the wallpaper heavily blurred and a
# little darker, so the clock, avatar and password field stay legible.
import sys

from PIL import Image, ImageEnhance, ImageFilter

src, out = sys.argv[1], sys.argv[2]
img = Image.open(src).convert("RGB").resize((1920, 1080), Image.LANCZOS)
# Blur at a quarter size: same look, much faster, and smoother gradients.
small = img.resize((480, 270), Image.LANCZOS).filter(ImageFilter.GaussianBlur(14))
img = small.resize((1920, 1080), Image.BICUBIC).filter(ImageFilter.GaussianBlur(6))
img = ImageEnhance.Color(img).enhance(1.25)
img = ImageEnhance.Brightness(img).enhance(0.78)
img.save(out, "JPEG", quality=88, optimize=True, progressive=True)
