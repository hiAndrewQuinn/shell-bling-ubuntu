#!/bin/sh
# Install fzf with shell keybindings. Per-user clone into ~/.fzf — that's what
# enables `Ctrl+R` and `Alt+C` in fish.

install_fzf() {
  case "$DISTRO" in
    macos) brew install fzf ;;
    *)
      pkg_install fzf 2> /dev/null || true
      ;;
  esac

  # Always clone the upstream repo for `install` (keybindings + completion).
  if [ ! -d "$HOME/.fzf" ]; then
    log "Cloning fzf for keybindings"
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  fi
  "$HOME/.fzf/install" --all --no-update-rc > /dev/null
}
