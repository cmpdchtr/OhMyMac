# SPDX-License-Identifier: GPL-3.0-or-later
#
# Folds a dark GTK 4 stylesheet into an @media (prefers-color-scheme: dark)
# block so one ~/.config/gtk-4.0/gtk.css follows the system light/dark switch
# (libadwaita ignores gtk-dark.css). @define-color cannot live inside @media,
# so every named colour the dark sheet defines is inlined into its rules;
# @keyframes are dropped (the light sheet already declares them).
#
# Usage: awk -f cssmerge.awk dark.css
#   Prints the dark rules wrapped in the media query.

function resolve(value,    guard, name, changed) {
  for (guard = 0; guard < 16; guard++) {
    changed = 0
    while (match(value, /@[A-Za-z_][A-Za-z0-9_-]*/)) {
      name = substr(value, RSTART + 1, RLENGTH - 1)
      if (!(name in color)) break
      value = substr(value, 1, RSTART - 1) color[name] substr(value, RSTART + RLENGTH)
      changed = 1
    }
    if (!changed) break
  }
  return value
}

function inline(line,    out, name) {
  out = ""
  while (match(line, /@[A-Za-z_][A-Za-z0-9_-]*/)) {
    name = substr(line, RSTART + 1, RLENGTH - 1)
    if (name in color) {
      out = out substr(line, 1, RSTART - 1) color[name]
    } else {
      out = out substr(line, 1, RSTART + RLENGTH - 1)
    }
    line = substr(line, RSTART + RLENGTH)
  }
  return out line
}

# Pass 1: collect named colours.
FNR == NR {
  if ($0 ~ /^[ \t]*@define-color[ \t]/) {
    line = $0
    sub(/^[ \t]*@define-color[ \t]+/, "", line)
    name = line; sub(/[ \t].*/, "", name)
    value = line; sub(/^[^ \t]+[ \t]+/, "", value); sub(/;[ \t]*$/, "", value)
    color[name] = value
  }
  next
}

# Pass 2: emit rules.
FNR == 1 {
  for (n in color) color[n] = resolve(color[n])
  print "@media (prefers-color-scheme: dark) {"
}
/^[ \t]*@define-color[ \t]/ { next }
/^[ \t]*@import[ \t]/ { next }
/^[ \t]*@keyframes[ \t]/ { skipping = 1; depth = 0 }
skipping {
  depth += gsub(/\{/, "{") - gsub(/\}/, "}")
  if (depth <= 0 && $0 ~ /\}/) skipping = 0
  next
}
{ print inline($0) }
END { print "}" }
