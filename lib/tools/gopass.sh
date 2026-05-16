#!/bin/sh
# Install gopass — modern, pass-compatible password manager.

install_gopass() {
  has_cmd gopass && return 0
  case "$DISTRO" in
    macos)
      brew install gopass
      return $?
      ;;
    fedora) pkg_install gopass && return 0 ;;
  esac

  # gopass official apt repo
  log "Adding gopass apt repo"
  sudo_run mkdir -p /etc/apt/keyrings
  curl -fsSL https://packages.gopass.pw/repo/gpg.pub |
    sudo_run gpg --dearmor -o /etc/apt/keyrings/gopass-archive-keyring.gpg
  printf 'deb [signed-by=/etc/apt/keyrings/gopass-archive-keyring.gpg] https://packages.gopass.pw/repos/gopass stable main\n' |
    sudo_run tee /etc/apt/sources.list.d/gopass.list > /dev/null
  sudo_run chmod 644 /etc/apt/keyrings/gopass-archive-keyring.gpg /etc/apt/sources.list.d/gopass.list
  _PKG_UPDATED=0
  pkg_install gopass
}
