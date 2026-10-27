#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# Generates the OhMyMac "Tahoe Glass" wallpapers (original artwork):
#   python3 tools/gen-wallpaper.py src/wallpapers
# Flowing glass ribbons over a deep gradient, in light and dark variants.
import sys

W, H = 3840, 2160


def make(dark):
    # Palette: deep navy → electric blue (dark); airy sky → cobalt (light).
    if dark:
        sky = [(0, "#01030f"), (0.55, "#061a52"), (1, "#0b3bb8")]
        silk = [("#0b2a8f", "#1e5bff", "#9cc3ff"), ("#06135a", "#1747d6", "#5f9bff"), ("#0a1f73", "#2f6bff", "#c7dcff")]
        shade, glow, edge = "#000214", "#2f6bff", 0.75
    else:
        sky = [(0, "#eaf3ff"), (0.5, "#a9cbff"), (1, "#3d7cf5")]
        silk = [("#5b8ff9", "#cfe1ff", "#ffffff"), ("#2f6bff", "#8fb6ff", "#eaf2ff"), ("#1d4ed8", "#6ea0ff", "#ffffff")]
        shade, glow, edge = "#0b2a8f", "#ffffff", 0.95

    defs = ['<linearGradient id="sky" x1="0" y1="0" x2="0.4" y2="1">'
            + "".join(f'<stop offset="{o}" stop-color="{c}"/>' for o, c in sky) + "</linearGradient>",
            f'<radialGradient id="glow" cx="0.72" cy="0.38" r="0.5"><stop offset="0" stop-color="{glow}" stop-opacity="0.45"/>'
            f'<stop offset="1" stop-color="{glow}" stop-opacity="0"/></radialGradient>']
    for b in (3, 10, 30, 70):
        defs.append(f'<filter id="b{b}" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="{b}"/></filter>')
    # Each silk band shades across its thickness: dark underside, bright crest.
    for i, (lo, mid, hi) in enumerate(silk):
        defs.append(f'<linearGradient id="s{i}" x1="0" y1="1" x2="0.15" y2="0">'
                    f'<stop offset="0" stop-color="{lo}"/><stop offset="0.6" stop-color="{mid}"/><stop offset="1" stop-color="{hi}"/></linearGradient>')

    def band(top, bottom, grad, op=1.0, blur=3):
        return f'<path d="{top} L {bottom} Z" fill="url(#{grad})" opacity="{op}" filter="url(#b{blur})"/>'

    def crest(top, width, op):
        return f'<path d="{top}" fill="none" stroke="#ffffff" stroke-width="{width}" stroke-linecap="round" opacity="{op}" filter="url(#b3)"/>'

    t1 = "M-200 1500 C 700 1050 1500 1350 2250 1000 S 3400 250 4100 380"
    t2 = "M-200 1850 C 800 1350 1700 1700 2500 1300 S 3500 700 4100 760"
    t3 = "M-200 2150 C 900 1750 1900 2050 2750 1650 S 3700 1150 4100 1180"
    body = ['<rect width="100%" height="100%" fill="url(#sky)"/>', '<rect width="100%" height="100%" fill="url(#glow)"/>',
            # Shadows cast between the bands give the depth.
            f'<path d="{t2} L 4100 2300 L -200 2300 Z" fill="{shade}" opacity="0.55" filter="url(#b70)" transform="translate(0,-60)"/>',
            band(t1, "4100 2300 L -200 2300", "s0", 0.95),
            crest(t1, 6, edge),
            f'<path d="{t3} L 4100 2300 L -200 2300 Z" fill="{shade}" opacity="0.5" filter="url(#b70)" transform="translate(0,-70)"/>',
            band(t2, "4100 2300 L -200 2300", "s1", 0.97),
            crest(t2, 5, edge * 0.85),
            f'<path d="M-200 2300 L 4100 2300 L 4100 1500 C 3500 1600 2600 2200 -200 2300 Z" fill="{shade}" opacity="0.35" filter="url(#b70)"/>',
            band(t3, "4100 2300 L -200 2300", "s2", 0.98),
            crest(t3, 4, edge * 0.7)]

    return (f'<?xml version="1.0" encoding="UTF-8"?>\n<!-- OhMyMac "Tahoe Glass" — original artwork, CC BY-SA 4.0 -->\n'
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">\n<defs>\n'
            + "\n".join(defs) + "\n</defs>\n" + "\n".join(body) + "\n</svg>\n")


out = sys.argv[1] if len(sys.argv) > 1 else "src/wallpapers"
for dark in (False, True):
    with open(f"{out}/ohmymac-{'dark' if dark else 'light'}.svg", "w") as f:
        f.write(make(dark))
