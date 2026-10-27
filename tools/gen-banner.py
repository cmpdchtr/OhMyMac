#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
# Regenerates the README artwork: python3 tools/gen-banner.py docs/assets
import sys
OUT=sys.argv[1]
W,H=1600,720
FONT="-apple-system, BlinkMacSystemFont, 'SF Pro Display', Inter, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif"

def waves(dark):
    if dark:
        sky=[(0,"#0b1226"),(0.6,"#151a3a"),(1,"#2a1842")]
        lay=[("#1d2f66","#3a2a6e"),("#1a3a8a","#4b2f8a"),("#1f4fb8","#5a35a8"),("#2a66e0","#6a3fd0")]
        glow=("#6b8cff",0.38)
    else:
        sky=[(0,"#cfe3ff"),(0.55,"#e9e3ff"),(1,"#ffe9f1")]
        lay=[("#a8c8ff","#c9b8ff"),("#7fa8f5","#b49cf2"),("#5b86e8","#9a7de6"),("#3c63d0","#7a5bd6")]
        glow=("#ffffff",0.8)
    sx,sy=W/3840,H/2160
    shapes=[
     "M-100 1180 C 520 940 1080 1010 1620 1180 S 2860 1320 3940 980 L 3940 2260 L -100 2260 Z",
     "M-100 1440 C 640 1240 1300 1330 1900 1500 S 3080 1640 3940 1340 L 3940 2260 L -100 2260 Z",
     "M-100 1700 C 760 1560 1500 1640 2180 1780 S 3300 1900 3940 1700 L 3940 2260 L -100 2260 Z",
     "M-100 1950 C 900 1860 1700 1910 2400 2000 S 3500 2080 3940 1960 L 3940 2260 L -100 2260 Z"]
    d=[f'<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">'+''.join(f'<stop offset="{o}" stop-color="{c}"/>' for o,c in sky)+'</linearGradient>',
       f'<radialGradient id="glow" cx="0.70" cy="0.25" r="0.6"><stop offset="0" stop-color="{glow[0]}" stop-opacity="{glow[1]}"/><stop offset="1" stop-color="{glow[0]}" stop-opacity="0"/></radialGradient>']
    body=['<rect width="100%" height="100%" fill="url(#sky)"/>','<rect width="100%" height="100%" fill="url(#glow)"/>']
    for i,(a,b) in enumerate(lay):
        d.append(f'<linearGradient id="w{i}" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{a}"/><stop offset="1" stop-color="{b}"/></linearGradient>')
        body.append(f'<path transform="scale({sx:.5f} {sy:.5f})" d="{shapes[i]}" fill="url(#w{i})" filter="url(#soft)"/>')
    return d,body

def banner(dark):
    fg = "#ffffff" if dark else "#14161f"
    fg2 = "rgba(255,255,255,0.72)" if dark else "rgba(20,22,31,0.62)"
    glass = "rgba(30,30,34,0.72)" if dark else "rgba(255,255,255,0.72)"
    glass2 = "rgba(44,44,48,0.86)" if dark else "rgba(250,250,252,0.90)"
    stroke = "rgba(255,255,255,0.14)" if dark else "rgba(255,255,255,0.85)"
    tile = "rgba(255,255,255,0.10)" if dark else "rgba(0,0,0,0.06)"
    line = "rgba(255,255,255,0.10)" if dark else "rgba(0,0,0,0.08)"
    side = "rgba(42,42,46,0.80)" if dark else "rgba(233,231,236,0.85)"
    accent = "#0a84ff" if dark else "#007aff"
    defs,bg=waves(dark)
    defs += [
      '<filter id="soft" x="-10%" y="-10%" width="120%" height="120%"><feGaussianBlur stdDeviation="6"/></filter>',
      '<filter id="shadow" x="-0.2" y="-0.2" width="1.4" height="1.6"><feDropShadow dx="0" dy="18" stdDeviation="22" flood-color="#000" flood-opacity="%s"/></filter>' % ("0.55" if dark else "0.22"),
      '<filter id="ishadow" x="-0.3" y="-0.3" width="1.6" height="1.7"><feDropShadow dx="0" dy="4" stdDeviation="5" flood-color="#000" flood-opacity="0.25"/></filter>',
      '<linearGradient id="title" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>' % (("#ffffff","#b9c8ff") if dark else ("#0f1a3d","#4a3fb8")),
    ]
    icons=[("#5ac8fa","#007aff"),("#ffd60a","#ff9f0a"),("#30d158","#248a3d"),("#ff375f","#bf5af2"),("#64d2ff","#5e5ce6"),("#8e8e93","#48484a"),("#ff9f0a","#ff375f")]
    for i,(a,b) in enumerate(icons):
        defs.append(f'<linearGradient id="i{i}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{a}"/><stop offset="1" stop-color="{b}"/></linearGradient>')
    s=[]
    # menu bar
    mb="rgba(0,0,0,0.28)" if dark else "rgba(255,255,255,0.45)"
    s.append(f'<rect width="{W}" height="30" fill="{mb}"/>')
    x=22
    s.append(f'<circle cx="{x+6}" cy="15" r="6" fill="none" stroke="{fg}" stroke-width="2"/>'); x+=28
    for i,item in enumerate(["OhMyMac","File","Edit","View","Window","Help"]):
        s.append(f'<text x="{x}" y="20" font-size="13.5" font-weight="{700 if i==0 else 500}" fill="{fg}">{item}</text>')
        x+= len(item)*(9.6 if i==0 else 8.0)+20
    rx=W-22
    s.append(f'<text x="{rx}" y="20" font-size="13.5" font-weight="500" fill="{fg}" text-anchor="end">Tue 27 Oct  14:05</text>')
    rx-=150
    # status icons: control centre, battery, wifi
    s.append(f'<g transform="translate({rx},15)" fill="none" stroke="{fg}" stroke-width="1.7" stroke-linecap="round">'
             f'<rect x="-10" y="-6" width="20" height="5" rx="2.5"/><rect x="-10" y="1" width="20" height="5" rx="2.5"/>'
             f'<rect x="-46" y="-6" width="24" height="12" rx="3.5"/><rect x="-43.5" y="-3.5" width="15" height="7" rx="1.5" fill="{fg}" stroke="none"/><path d="M-20 -2v4"/>'
             f'<path d="M-76 -1.5a11 11 0 0 1 16 0M-73 1.8a6.5 6.5 0 0 1 10 0"/><circle cx="-68" cy="5" r="1.4" fill="{fg}" stroke="none"/></g>')
    # title block
    s.append(f'<text x="96" y="268" font-size="112" font-weight="800" letter-spacing="-4" fill="url(#title)">OhMyMac</text>')
    s.append(f'<text x="100" y="322" font-size="27" font-weight="500" fill="{fg2}">A macOS look for GNOME 51 — on any distro.</text>')
    px=100
    for p in ["GTK 3","GTK 4 · libadwaita","GNOME Shell","GDM","Flatpak"]:
        w=len(p)*9.6+34
        s.append(f'<rect x="{px}" y="352" width="{w:.0f}" height="38" rx="19" fill="{glass}" stroke="{stroke}"/>')
        s.append(f'<text x="{px+w/2:.0f}" y="377" font-size="16" font-weight="600" text-anchor="middle" fill="{fg}">{p}</text>')
        px+=w+10
    # window
    wx,wy,ww,wh=800,92,520,380
    s.append(f'<g filter="url(#shadow)"><rect x="{wx}" y="{wy}" width="{ww}" height="{wh}" rx="16" fill="{glass2}" stroke="{stroke}"/></g>')
    s.append(f'<path d="M{wx+16} {wy}h168v{wh}h-168a16 16 0 0 1-16-16v-{wh-32}a16 16 0 0 1 16-16z" fill="{side}"/>')
    for i,c in enumerate(["#ff5f57","#febc2e","#28c840"]):
        s.append(f'<circle cx="{wx+22+i*20}" cy="{wy+22}" r="6.5" fill="{c}"/>')
    rows=["Recents","Applications","Desktop","Documents","Downloads"]
    for i,r in enumerate(rows):
        y=wy+66+i*32
        if i==1: s.append(f'<rect x="{wx+10}" y="{y-20}" width="164" height="28" rx="7" fill="{tile}"/>')
        s.append(f'<circle cx="{wx+28}" cy="{y-6}" r="6" fill="{accent}" opacity="{0.9 if i==1 else 0.55}"/>')
        s.append(f'<text x="{wx+44}" y="{y}" font-size="14" font-weight="500" fill="{fg}">{r}</text>')
    s.append(f'<text x="{wx+208}" y="{wy+30}" font-size="16" font-weight="700" fill="{fg}">Appearance</text>')
    s.append(f'<line x1="{wx+184}" y1="{wy+48}" x2="{wx+ww}" y2="{wy+48}" stroke="{line}"/>')
    # appearance cards
    for i,(lbl,d) in enumerate([("Light",False),("Dark",True)]):
        cx=wx+208+i*120
        s.append(f'<rect x="{cx}" y="{wy+68}" width="104" height="70" rx="10" fill="{"#2c2c2e" if d else "#f2f2f7"}" stroke="{accent if (i==1)==dark else line}" stroke-width="{3 if (i==1)==dark else 1}"/>')
        s.append(f'<rect x="{cx+12}" y="{wy+82}" width="80" height="10" rx="5" fill="{"#48484a" if d else "#d1d1d6"}"/>')
        s.append(f'<rect x="{cx+12}" y="{wy+100}" width="50" height="10" rx="5" fill="{accent}"/>')
        s.append(f'<text x="{cx+52}" y="{wy+160}" font-size="13" font-weight="500" text-anchor="middle" fill="{fg2}">{lbl}</text>')
    # accent dots
    s.append(f'<text x="{wx+208}" y="{wy+200}" font-size="14" font-weight="500" fill="{fg}">Accent</text>')
    for i,c in enumerate(["#007aff","#30b0c7","#28cd41","#ffcc00","#ff9500","#ff3b30","#ff2d55","#af52de","#8e8e93"]):
        cx=wx+214+i*26
        s.append(f'<circle cx="{cx}" cy="{wy+222}" r="9" fill="{c}"/>')
        if i==0: s.append(f'<circle cx="{cx}" cy="{wy+222}" r="13" fill="none" stroke="{c}" stroke-width="2"/>')
    # toggles rows
    for i,(lbl,on) in enumerate([("Reduce transparency",False),("Show scroll bars automatically",True)]):
        y=wy+272+i*44
        s.append(f'<line x1="{wx+208}" y1="{y-22}" x2="{wx+ww-24}" y2="{y-22}" stroke="{line}"/>')
        s.append(f'<text x="{wx+208}" y="{y+5}" font-size="14" font-weight="500" fill="{fg}">{lbl}</text>')
        tx=wx+ww-66
        s.append(f'<rect x="{tx}" y="{y-11}" width="40" height="23" rx="11.5" fill="{accent if on else tile}"/>')
        s.append(f'<circle cx="{tx+(28 if on else 12)}" cy="{y+0.5}" r="9.5" fill="#fff" filter="url(#ishadow)"/>')
    # control center
    cx0,cy0,cw,ch=1340,268,236,250
    s.append(f'<g filter="url(#shadow)"><rect x="{cx0}" y="{cy0}" width="{cw}" height="{ch}" rx="24" fill="{glass}" stroke="{stroke}"/></g>')
    tiles=[(cx0+14,cy0+14,101,52,True,"Wi-Fi"),(cx0+121,cy0+14,101,52,True,"Bluetooth"),(cx0+14,cy0+72,101,52,False,"Focus"),(cx0+121,cy0+72,101,52,dark,"Dark")]
    for (x0,y0,w0,h0,on,lbl) in tiles:
        s.append(f'<rect x="{x0}" y="{y0}" width="{w0}" height="{h0}" rx="14" fill="{tile}"/>')
        s.append(f'<circle cx="{x0+22}" cy="{y0+26}" r="13" fill="{accent if on else ("rgba(255,255,255,0.18)" if dark else "rgba(0,0,0,0.12)")}"/>')
        s.append(f'<text x="{x0+42}" y="{y0+31}" font-size="11.5" font-weight="600" fill="{fg}">{lbl}</text>')
    for i,lbl in enumerate(["Display","Sound"]):
        y0=cy0+134+i*56
        s.append(f'<rect x="{cx0+14}" y="{y0}" width="{cw-28}" height="48" rx="14" fill="{tile}"/>')
        s.append(f'<text x="{cx0+28}" y="{y0+19}" font-size="12" font-weight="600" fill="{fg}">{lbl}</text>')
        s.append(f'<rect x="{cx0+28}" y="{y0+28}" width="{cw-56}" height="8" rx="4" fill="{"rgba(255,255,255,0.18)" if dark else "rgba(0,0,0,0.10)"}"/>')
        s.append(f'<rect x="{cx0+28}" y="{y0+28}" width="{(cw-56)*(0.7 if i==0 else 0.45):.0f}" height="8" rx="4" fill="#ffffff" opacity="0.95"/>')
    # dock
    n=len(icons); isz=58; gap=12; dw=n*isz+(n-1)*gap+28; dx=(W-dw)/2; dy=H-104
    s.append(f'<g filter="url(#shadow)"><rect x="{dx:.0f}" y="{dy}" width="{dw:.0f}" height="{isz+28}" rx="24" fill="{glass}" stroke="{stroke}"/></g>')
    for i in range(n):
        ix=dx+14+i*(isz+gap)
        s.append(f'<rect x="{ix:.0f}" y="{dy+14}" width="{isz}" height="{isz}" rx="14" fill="url(#i{i})" filter="url(#ishadow)"/>')
        s.append(f'<rect x="{ix+0.5:.1f}" y="{dy+14.5}" width="{isz-1}" height="{isz/2:.0f}" rx="13.5" fill="#fff" opacity="0.12"/>')
        if i in (0,2,4):
            s.append(f'<circle cx="{ix+isz/2:.0f}" cy="{dy+isz+21}" r="2.4" fill="{fg}"/>')
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" font-family="{FONT}">
<!-- OhMyMac banner — illustration, CC BY-SA 4.0 -->
<defs>
{chr(10).join(defs)}
<clipPath id="frame"><rect width="{W}" height="{H}" rx="28"/></clipPath>
</defs>
<g clip-path="url(#frame)">
{chr(10).join(bg)}
{chr(10).join(s)}
</g>
</svg>
'''
for dark in (False,True):
    open(f"{OUT}/banner-{'dark' if dark else 'light'}.svg","w").write(banner(dark))
