#!/bin/sh
# Git config: use delta as pager. Idempotent — checks before appending.

setup_git() {
  has_cmd git || return 0
  _gc="$HOME/.gitconfig"
  touch "$_gc"
  if grep -q '^\[delta\]' "$_gc" 2> /dev/null; then
    return 0
  fi
  log "Configuring git to use delta as pager"
  cat << 'EOF' >> "$_gc"

[core]
    pager = delta

[interactive]
    diffFilter = delta --color-only

[delta]
    navigate = true
    light = false

[merge]
    conflictstyle = diff3

[diff]
    colorMoved = default
EOF
}
