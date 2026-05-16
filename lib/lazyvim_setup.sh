#!/bin/sh
# LazyVim starter. Skip if user already has an nvim config.

setup_lazyvim() {
  has_cmd nvim || {
    warn "nvim not installed; skipping LazyVim"
    return 0
  }
  if [ -d "$HOME/.config/nvim" ] && [ -n "$(ls -A "$HOME/.config/nvim" 2> /dev/null)" ]; then
    log "Existing ~/.config/nvim found; leaving it alone"
    return 0
  fi
  log "Installing LazyVim starter"
  rm -rf "$HOME/.config/nvim"
  git clone --depth 1 https://github.com/LazyVim/starter "$HOME/.config/nvim"
  rm -rf "$HOME/.config/nvim/.git"
}
