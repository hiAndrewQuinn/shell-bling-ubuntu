#!/bin/sh
# Install zoxide.

install_zoxide() {
  has_cmd zoxide && return 0
  case "$DISTRO" in
    macos)
      brew install zoxide
      return $?
      ;;
    fedora) pkg_install zoxide && return 0 ;;
  esac
  if pkg_available zoxide; then
    pkg_install zoxide && return 0
  fi
  log "Installing zoxide via official script"
  curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh |
    sudo_run bash -s -- > /dev/null
}
