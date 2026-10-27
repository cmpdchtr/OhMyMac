# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [1.3.0] — 2026-10-27

Head-to-head with MacTahoe on GNOME 51 showed its GTK 3 and Shell work is more
faithful than OhMyMac's own, so the default install now builds on it.

### Added
- **Hybrid theme (default)**: MacTahoe (vinceliuice, MIT) as the GTK 3 / GTK 4 /
  Shell base, from its prebuilt release archives at a pinned commit, verified
  by SHA-256 — no upstream script is executed. `--theme ohmymac` keeps the
  OhMyMac-only theme.
- One libadwaita stylesheet for MacTahoe that follows light/dark on its own:
  the dark sheet is folded into `@media (prefers-color-scheme: dark)` by
  `lib/cssmerge.awk` (libadwaita ignores `gtk-dark.css`).
- OhMyMac Tahoe layer over MacTahoe (`src/sass/gtk4/hybrid.scss`): floating
  sidebar, accent sidebar symbols, macOS window shadows.
- Dark menu bar text in light mode.

### Fixed
- The workspace indicator could reappear after another extension showed it.
- `ohmymac-sync` now also switches MacTahoe between light and dark.

## [1.2.0] — 2026-10-27

### Added
- New "Tahoe Glass" wallpapers (original artwork, `tools/gen-wallpaper.py`):
  deep blue silk bands with glossy crests.
- A full macOS-order Dock (Finder, browser, Mail, Maps, Photos, Calendar,
  Music, Weather, Notes, App Store, Terminal, System Settings) built from the
  apps actually installed; 56 px icons.
- Large soft macOS window shadows, accent-tinted Finder sidebar symbols, a
  cool sidebar tint in place of vibrancy, no title inside sidebars.
- Bundled **OhMyMac** Shell extension (GNOME 47–51) for a real Mac menu bar:
  the focused app's name in bold with New Window / Hide / Quit, the clock on
  the right edge, notification banners at the top right, no workspace pill.
- Spotlight on Super+Space (Liquid Glass launcher); input sources move to
  Ctrl+Space like macOS.
- GTK 3 brought to the Tahoe style: capsule toolbar buttons and tab groups,
  capsule switch and slider knobs.
- Extension lists accept `local:<dir>` for extensions shipped in this repo.

### Changed
- The MacTahoe icon theme is fetched at a pinned commit (its installer runs
  locally), no longer from a moving branch.

### Verified on GNOME 51.0
- Install, uninstall (settings restored, nothing left behind) and the login
  screen bundle (restored byte-for-byte) on Fedora 45.

## [1.1.0] — 2026-10-27

Tahoe redesign, verified on a real GNOME Shell 51.0 / GTK 4.24 / libadwaita 1.10
(Fedora 45).

### Added
- Liquid Glass (ryohsuke1231/liquid-glass, MIT) in the recommended profile:
  real refracting glass for the dock, menus, Control Center, Notification
  Center and OSDs. Fetched from a pinned upstream commit.
- Extension lists accept `git:<url>@<commit>[:<dir>]` sources for extensions
  that are not on extensions.gnome.org.
- Blur my Shell back in the recommended profile, limited to the Launchpad and
  overview backdrop.
- Real GNOME 51 screenshots in the README.

### Changed
- GTK 4 / libadwaita layer redesigned after macOS 26 Tahoe: unified toolbar
  with glass capsule buttons, floating rounded sidebar, 20 px window corners,
  capsule switches and slider knobs, pill search fields and toasts.
- Traffic lights are drawn on the button icon, so libadwaita 1.10 can no
  longer stretch them into pills.
- Menu bar is fully transparent with a soft text shadow.
- If the stock Shell bundle has no light stylesheet, the light variant now
  falls back to `gnome-shell-dark.css` instead of importing a missing file.

### Fixed
- The installer aborted on Fedora: `/etc/os-release` defines `VARIANT`, which
  overwrote `--variant`. os-release is now read in an isolated subshell.
- The installer stopped silently after the first freshly downloaded extension
  (`gnome-extensions enable` fails until the Shell reloads, and `set -e`
  turned that into an exit).
- `cmd | grep -q` checks under `pipefail` could fail spuriously, so GSettings
  presets were skipped and the Inter font was not detected.
- Icon and cursor themes are no longer applied when their download failed.

## [1.0.0] — 2026-10-27

Complete rewrite, inspired by [macW1Y](https://github.com/w1nyear/macW1Y-GTK-Theme).

### Added
- SCSS sources with a single macOS palette for GTK 3, GTK 4/libadwaita and
  GNOME Shell; light and dark variants.
- GTK 4 stylesheet driven by libadwaita CSS variables with `prefers-color-scheme`.
- GNOME Shell theme for GNOME 47–51 that layers on the system's stock stylesheet.
- Traffic-light window controls, macOS-style menus, switches, sidebars, Control
  Center, Notification Center, Dock, OSD and lock screen.
- Multi-distribution installer: apt, dnf, pacman, zypper, xbps, apk, emerge,
  eopkg; immutable systems and NixOS guidance.
- Extensions from extensions.gnome.org matched to the running Shell version,
  with `minimal`, `recommended` and `full` profiles.
- GSettings presets with automatic backup and restore.
- Optional GDM login screen theming with backup (Debian alternatives aware).
- Flatpak integration, `ohmymac-sync` light/dark helper, original wallpapers.
- Uninstaller driven by an install manifest.
- Test suite, GitHub Actions CI across seven distributions, Arch and Fedora
  packaging.
