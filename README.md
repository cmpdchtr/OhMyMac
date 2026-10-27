<div align="center">

# OhMyMac

**A macOS look for GNOME 51 — on any Linux distribution.**

GTK 3 · GTK 4 / libadwaita · GNOME Shell · GDM · Flatpak

[![CI](https://github.com/cmpdchtr/OhMyMac/actions/workflows/ci.yml/badge.svg)](https://github.com/cmpdchtr/OhMyMac/actions/workflows/ci.yml)
![GNOME 47–51](https://img.shields.io/badge/GNOME-47–51-4a86cf?logo=gnome&logoColor=white)
![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-blue)

[Features](#features) · [Install](#install) · [What it changes](#what-it-changes) · [Uninstall](#uninstall) · [Development](#development)

</div>

---

OhMyMac turns GNOME into something very close to macOS Tahoe: traffic-light
window controls, macOS colours and geometry, a translucent menu bar, a Control
Center, a glass Dock, Inter (or SF Pro, if you have it), MacTahoe icons and
macOS cursors.

It is inspired by [macW1Y](https://github.com/w1nyear/macW1Y-GTK-Theme), rebuilt
from scratch around a different set of principles:

| macW1Y | OhMyMac |
| --- | --- |
| Ubuntu + `apt` only | 9 distribution families, immutable systems, NixOS |
| ~150 MB of bundled themes, icons, fonts and third-party extensions | Small SCSS sources; icons, cursors and extensions come from upstream |
| Full copy of one GNOME Shell version's CSS | Thin layer over *your* Shell's stock CSS — survives GNOME updates |
| Changes GRUB, Plymouth, sysctl, udev, sudoers… | Appearance only; system files only with an explicit `--gdm` |
| Uninstaller guesses what to delete | Install manifest + backup of every changed setting |

## Features

- **GTK 4 / libadwaita** — macOS palette through libadwaita's public CSS
  variables; light and dark in a single stylesheet (`prefers-color-scheme`);
  macOS colours for all nine GNOME accent colours.
- **GTK 3** — built on top of the Adwaita theme compiled into libgtk-3, so every
  widget OhMyMac doesn't restyle stays correct.
- **Windows** — traffic-light buttons on the left with glyphs on hover, 14 px
  corners, thin overlay scrollbars, macOS switches, checkboxes, sliders and
  accent-highlighted menus.
- **GNOME Shell** — translucent menu bar, Quick Settings as Control Center,
  calendar and notifications as Notification Center, glass Dock (Dash to Dock
  included), OSD, switchers, dialogs and lock screen.
- **Automatic light/dark** — `ohmymac-sync` flips GTK 3, the Shell theme and
  icons together with the system switch.
- **Extensions** from extensions.gnome.org **for your exact GNOME version**;
  incompatible ones are skipped instead of breaking the session.
- **Flatpak** — sandboxed apps get the themes, icons and libadwaita styling.
- **Login screen (GDM)** — optional, with backup and restore.
- **Clean uninstall** — `uninstall.sh` restores your previous settings and files.

## Supported systems

| Family | Examples | Package manager |
| --- | --- | --- |
| Debian | Debian, Ubuntu, Linux Mint, Pop!\_OS, Zorin, elementary | `apt` |
| Fedora | Fedora Workstation, Nobara, RHEL/Alma/Rocky | `dnf` |
| Arch | Arch, EndeavourOS, Manjaro, CachyOS, Garuda | `pacman` |
| openSUSE | Tumbleweed, Leap, Slowroll | `zypper` |
| Void | Void Linux (glibc/musl) | `xbps` |
| Alpine | Alpine, postmarketOS | `apk` |
| Gentoo | Gentoo, Funtoo | `emerge` |
| Solus | Solus | `eopkg` |
| Immutable | Silverblue, Bluefin, Aurora, Aeon, Vanilla OS | — (everything goes to `$HOME`) |
| NixOS | NixOS | — (prints packages for `configuration.nix`) |

**GNOME:** target **51**, supported **47–51**. Older versions get working GTK
themes, but the Shell theme may look off. GNOME 50+ is Wayland-only, and so is
OhMyMac's focus.

## Install

```bash
git clone https://github.com/cmpdchtr/OhMyMac.git
cd OhMyMac
./install.sh
```

The installer shows what it detected (distribution, GNOME version, session) and
asks which components to install. Root is only needed for dependency packages
and the optional login screen — `sudo`, `doas` or `run0` are called on demand.
**Do not run `install.sh` with `sudo`.**

Afterwards, **log out and back in**: on Wayland the Shell cannot restart, so new
extensions load at the next login.

### Common recipes

```bash
./install.sh --all -y                      # everything, no questions (incl. GDM)
./install.sh --themes-only                 # just the themes
./install.sh --variant dark --accent purple
./install.sh --extensions minimal          # only User Themes
./install.sh --dry-run                     # show what would happen
sudo ./install.sh --system --themes-only   # themes for all users
```

### All options

| Option | Description |
| --- | --- |
| `--all` | Everything, including the full extension set and the login screen |
| `--themes-only` | GTK 3 / GTK 4 / libadwaita / Shell themes only |
| `--no-icons`, `--no-cursors`, `--no-fonts`, `--no-wallpaper` | Skip a component |
| `--no-extensions` / `--extensions minimal\|recommended\|full` | GNOME Shell extensions |
| `--no-settings` | Don't change any GNOME settings |
| `--no-flatpak` | Skip Flatpak integration |
| `--gdm` | Style the login screen (needs root) |
| `--variant auto\|light\|dark` | Colour scheme (`auto` follows the system) |
| `--accent blue\|teal\|green\|yellow\|orange\|red\|pink\|purple\|slate` | Accent colour |
| `--system` | Install themes and icons for all users |
| `--dest DIR` | Stage files under `DIR` (for packagers) |
| `--no-deps` | Never call the package manager |
| `--allow-incompatible` | Install extensions not marked for your GNOME version |
| `--update-extensions` | Re-download extensions that are already installed |
| `-y`, `-n`, `-v` | No questions / dry run / verbose |

## What it changes

**Files** (all recorded in `~/.local/state/ohmymac/manifest`):

| Path | Contents |
| --- | --- |
| `~/.local/share/themes/OhMyMac-{Light,Dark}` | GTK 3, GTK 4 and Shell themes |
| `~/.themes/OhMyMac-*` | Symlinks for Flatpak |
| `~/.config/gtk-4.0/gtk.css` | libadwaita styling (your previous file is backed up) |
| `~/.local/share/gnome-shell/extensions/…` | Extensions from extensions.gnome.org |
| `~/.local/share/icons/{MacTahoe*,macOS*}` | Icons and cursors from upstream |
| `~/.local/share/fonts/Inter` | Inter, when the distribution has no package |
| `~/.local/share/backgrounds/ohmymac` | Original light/dark wallpaper pair |
| `~/.local/bin/ohmymac-sync`, `~/.config/autostart/ohmymac-sync.desktop` | Light/dark sync |

**GNOME settings** live in [`data/settings/`](data/settings) as plain
`schema key value` files. Each key's previous value is saved to
`~/.local/state/ohmymac/gsettings.backup` before it is first changed. Keys that
don't exist in your GNOME version are skipped.

**Extension profiles** live in [`data/extensions/`](data/extensions):

| Profile | Extensions |
| --- | --- |
| `minimal` | User Themes |
| `recommended` *(default)* | + Dash to Dock, Blur my Shell, AppIndicator, Logo Menu, Magic Lamp |
| `full` | + Kiwi, Just Perfection, Rounded Window Corners, Top Bar Organizer |

Conflicting extensions (e.g. Ubuntu Dock when Dash to Dock is installed) are
disabled automatically.

## Uninstall

```bash
./uninstall.sh                  # remove everything and restore your settings
./uninstall.sh --gdm            # also restore the stock login screen
./uninstall.sh --keep-settings  # keep the current GNOME settings
```

## How it works

```
src/sass/            SCSS sources: palette, tokens, GTK 3, GTK 4, Shell
  _palette.scss      macOS system colours (light and dark)
  _colors.scss       semantic colours for the active variant
  _tokens.scss       radii, sizes, motion
  gtk3/ gtk4/ gnome-shell/
lib/                 installer modules (bash)
  distro.sh          distribution, GNOME and immutable-system detection
  packages.sh        dependency → package mapping for 9 package managers
  build.sh           Sass compilation (sassc or Dart Sass)
  themes.sh          themes, libadwaita, Flatpak, fonts, icons, cursors
  extensions.sh      extensions.gnome.org for the running Shell version
  settings.sh        GSettings with backup and restore
  gdm.sh             login screen GResource rebuild
data/                extension profiles and settings presets
bin/ohmymac-sync     light/dark sync helper
packaging/           PKGBUILD (Arch) and .spec (Fedora)
tests/               unit tests, build checks, install round-trip
```

The key idea is **layering instead of copying**:

- the GTK 3 theme imports `resource:///org/gtk/libgtk/theme/Adwaita/gtk-contained.css`;
- libadwaita is styled through its public CSS variables;
- at install time the Shell theme gets an `@import` of the stock stylesheet that
  actually exists on your system (`gnome-shell-{light,dark}.css` on GNOME 47+,
  `gnome-shell.css` before).

So GNOME updates don't break the theme: everything OhMyMac doesn't touch stays
upstream.

## Development

```bash
make build     # compile CSS into build/
make lint      # shellcheck + build
make test      # full test suite (isolated $HOME, changes nothing)
make dist      # tar.xz with prebuilt CSS (installs without Sass)
```

CI runs shellcheck, builds with sassc and Dart Sass, parses the CSS with real
GTK 3 and GTK 4, and runs the installer on Ubuntu, Debian, Fedora, Arch,
openSUSE, Alpine and Void. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Fonts and trademarks

OhMyMac ships no Apple fonts, logos or wallpapers — their licences forbid
redistribution. If you own SF Pro, put it in `~/.local/share/fonts` and the
installer will use it instead of Inter. macOS is a trademark of Apple Inc.; this
project is not affiliated with Apple.

## Credits

- [w1nyear/macW1Y](https://github.com/w1nyear/macW1Y-GTK-Theme) — the original idea
- [vinceliuice](https://github.com/vinceliuice) — MacTahoe icons
- [ful1e5/apple_cursor](https://github.com/ful1e5/apple_cursor) — macOS cursors
- [rsms/inter](https://github.com/rsms/inter) — Inter typeface
- The authors of Dash to Dock, Blur my Shell, Kiwi and the other extensions

## License

[GPL-3.0-or-later](LICENSE). Wallpapers: CC BY-SA 4.0.
