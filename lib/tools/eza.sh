#!/bin/sh
# Install eza. Native apt on new enough Ubuntu/Debian; third-party repo otherwise.

install_eza() {
  has_cmd eza && return 0
  case "$DISTRO" in
    macos)
      brew install eza
      return $?
      ;;
    fedora) pkg_install eza && has_cmd eza && return 0 ;;
  esac

  if pkg_available eza; then
    pkg_install eza && return 0
  fi

  # gierens.de community repo. Works for older Debian/Ubuntu.
  log "Adding eza apt repo (gierens.de)"
  sudo_run mkdir -p /etc/apt/keyrings
  curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc |
    sudo_run gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  printf 'deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main\n' |
    sudo_run tee /etc/apt/sources.list.d/gierens.list > /dev/null
  sudo_run chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  _PKG_UPDATED=0
  pkg_install eza
}
