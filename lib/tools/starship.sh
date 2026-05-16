#!/bin/sh
# Install starship prompt.

install_starship() {
  has_cmd starship && return 0
  case "$DISTRO" in
    macos)
      brew install starship
      return $?
      ;;
    fedora) pkg_install starship && has_cmd starship && return 0 ;;
  esac
  log "Installing starship"
  curl -fsSL https://starship.rs/install.sh | sudo_run sh -s -- --yes > /dev/null
}
