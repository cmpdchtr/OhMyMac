# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

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
