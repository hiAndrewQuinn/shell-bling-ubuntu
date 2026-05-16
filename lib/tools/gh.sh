#!/bin/sh
# Install GitHub CLI.

install_gh() {
  has_cmd gh && return 0
  case "$DISTRO" in
    macos)
      brew install gh
      return $?
      ;;
    fedora) pkg_install gh && return 0 ;;
  esac
  if pkg_available gh; then
    pkg_install gh && return 0
  fi

  log "Adding GitHub CLI apt repo"
  sudo_run mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg |
    sudo_run dd of=/etc/apt/keyrings/githubcli-archive-keyring.gpg status=none
  sudo_run chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  printf 'deb [arch=%s signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\n' \
    "$ARCH" | sudo_run tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  _PKG_UPDATED=0
  pkg_install gh
}
