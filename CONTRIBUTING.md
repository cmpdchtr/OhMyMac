# Contributing to OhMyMac

Thanks for helping! A few rules keep the project maintainable.

## Ground rules

1. **Layer, don't fork.** Stylesheets build on top of the stock Adwaita / GNOME
   Shell CSS. Only style what makes the macOS look; never paste upstream CSS.
2. **Colours come from tokens.** Add values to `src/sass/_palette.scss` (raw
   colours) or `src/sass/_colors.scss` (semantic names), never inline hex codes
   in widget files.
3. **Sass must compile with both `sassc` and Dart Sass.** That means `@import`,
   no `@use`/modules and no `math.*` functions. CI checks both.
4. **The installer is user-first.** Write to `$HOME`, record every path with
   `manifest_add`, change settings only through `set_setting` (which backs them
   up), and keep `uninstall.sh` able to undo it.
5. **Every distribution counts.** New dependencies go into the table in
   `lib/packages.sh` for all families (use `-` when a distro lacks a package).

## Workflow

```bash
make build   # compile into build/
make test    # shellcheck, Sass build, unit tests, isolated install round-trip
```

To try your changes live, run `./install.sh --themes-only --no-deps`, then log
out and in (Shell) or restart the app (GTK). `GTK_DEBUG=interactive` opens the
GTK Inspector for live CSS editing.

## Supporting a new GNOME release

1. Bump `OHM_GNOME_TARGET` in `lib/distro.sh`.
2. Check that `/usr/share/gnome-shell/gnome-shell-theme.gresource` still
   provides `gnome-shell-{light,dark}.css` (`gresource list …`).
3. Review renamed Shell selectors in `src/sass/gnome-shell/_shell.scss`.
4. Update the version badge and table in `README.md` and `CHANGELOG.md`.

## Commit messages

Use the imperative mood and a component prefix, e.g.
`shell: round the OSD window`, `installer: support eopkg`.
