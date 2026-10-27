#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# Regenerates the README palette: python3 tools/gen-palette.py docs/assets
import sys
OUT=sys.argv[1]
FONT="-apple-system, BlinkMacSystemFont, 'SF Pro Text', Inter, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif"
acc=[("Blue","#007aff","#0a84ff"),("Teal","#30b0c7","#40c8e0"),("Green","#28cd41","#32d74b"),("Yellow","#ffcc00","#ffd60a"),
     ("Orange","#ff9500","#ff9f0a"),("Red","#ff3b30","#ff453a"),("Pink","#ff2d55","#ff375f"),("Purple","#af52de","#bf5af2"),("Slate","#8e8e93","#98989d")]
def make(dark):
    W,H=1600,300
    bg="#1c1c1e" if dark else "#f5f5f7"; card="#2c2c2e" if dark else "#ffffff"
    fg="#ffffff" if dark else "#1d1d1f"; fg2="rgba(255,255,255,0.55)" if dark else "rgba(0,0,0,0.5)"
    stroke="rgba(255,255,255,0.08)" if dark else "rgba(0,0,0,0.06)"
    s=[f'<rect width="{W}" height="{H}" rx="28" fill="{bg}"/>']
    s.append(f'<text x="56" y="62" font-size="22" font-weight="700" fill="{fg}">Accent colours</text>')
    s.append(f'<text x="56" y="90" font-size="15" fill="{fg2}">macOS system colours, mapped onto GNOME’s nine accents · Settings → Appearance</text>')
    cw=(W-112-8*16)/9
    for i,(n,l,d) in enumerate(acc):
        c=d if dark else l
        x=56+i*(cw+16)
        s.append(f'<rect x="{x:.1f}" y="120" width="{cw:.1f}" height="140" rx="18" fill="{card}" stroke="{stroke}"/>')
        s.append(f'<circle cx="{x+cw/2:.1f}" cy="172" r="28" fill="{c}"/>')
        if i==0: s.append(f'<circle cx="{x+cw/2:.1f}" cy="172" r="35" fill="none" stroke="{c}" stroke-width="3"/>')
        s.append(f'<text x="{x+cw/2:.1f}" y="228" font-size="15" font-weight="600" text-anchor="middle" fill="{fg}">{n}</text>')
        s.append(f'<text x="{x+cw/2:.1f}" y="248" font-size="12" text-anchor="middle" fill="{fg2}" font-family="ui-monospace, SFMono-Regular, Menlo, monospace">{c.upper()}</text>')
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" font-family="{FONT}">\n'+"\n".join(s)+"\n</svg>\n"
for dark in (False,True):
    open(f"{OUT}/palette-{'dark' if dark else 'light'}.svg","w").write(make(dark))
