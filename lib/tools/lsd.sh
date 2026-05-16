#!/bin/sh
# Install lsd from the project's .deb (no snap).

install_lsd() {
  has_cmd lsd && return 0
  case "$DISTRO" in
    macos)
      brew install lsd
      return $?
      ;;
    fedora) pkg_install lsd && has_cmd lsd && return 0 ;;
  esac
  if pkg_available lsd; then
    pkg_install lsd && return 0
  fi

  _ver=$(github_latest_tag lsd-rs/lsd)
  [ -n "$_ver" ] || {
    err "could not resolve lsd version"
    return 1
  }

  case "$ARCH" in
    amd64) _arch=amd64 ;;
    arm64) _arch=arm64 ;;
    *)
      err "no lsd .deb for arch $ARCH"
      return 1
      ;;
  esac

  _url="https://github.com/lsd-rs/lsd/releases/download/v${_ver}/lsd_${_ver}_${_arch}.deb"
  log "Installing lsd $_ver ($_arch)"
  install_deb "$_url"
}
