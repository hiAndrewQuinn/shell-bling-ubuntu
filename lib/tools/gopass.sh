#!/bin/sh
# Install gopass — modern, pass-compatible password manager.
# Prefer apt where available; fall back to GitHub release tarball.

install_gopass() {
  has_cmd gopass && return 0
  case "$DISTRO" in
    macos)
      brew install gopass
      return $?
      ;;
    fedora) pkg_install gopass && return 0 ;;
  esac
  if pkg_available gopass; then
    pkg_install gopass && return 0
  fi

  # Binary release fallback (more reliable than the apt repo across distros).
  __sb_ver=$(github_latest_tag gopasspw/gopass)
  [ -n "$__sb_ver" ] || {
    warn "could not resolve gopass version; skipping"
    return 0
  }
  case "$ARCH" in
    amd64) __sb_suffix=linux-amd64 ;;
    arm64) __sb_suffix=linux-arm64 ;;
    *)
      warn "no gopass build for arch $ARCH; skipping"
      return 0
      ;;
  esac
  __sb_url="https://github.com/gopasspw/gopass/releases/download/v${__sb_ver}/gopass-${__sb_ver}-${__sb_suffix}.tar.gz"
  __sb_dir=$(mktemp -d)
  log "Installing gopass $__sb_ver ($__sb_suffix)"
  fetch_to "$__sb_url" "$__sb_dir/gopass.tar.gz" || {
    rm -rf "$__sb_dir"
    return 1
  }
  tar -xzf "$__sb_dir/gopass.tar.gz" -C "$__sb_dir" gopass
  sudo_run install -m 0755 "$__sb_dir/gopass" /usr/local/bin/gopass
  rm -rf "$__sb_dir"
}
