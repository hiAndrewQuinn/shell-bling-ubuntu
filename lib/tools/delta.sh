#!/bin/sh
# Install git-delta (a.k.a. delta) — better git diffs.

install_delta() {
  has_cmd delta && return 0
  case "$DISTRO" in
    macos)
      brew install git-delta
      return $?
      ;;
    fedora) pkg_install git-delta && has_cmd delta && return 0 ;;
    # Alpine + Arch package is `delta` (provides /usr/bin/delta).
    alpine | arch) pkg_install delta && has_cmd delta && return 0 ;;
  esac
  if pkg_available git-delta; then
    pkg_install git-delta && has_cmd delta && return 0
  fi

  __sb_ver=$(github_latest_tag dandavison/delta)
  [ -n "$__sb_ver" ] || {
    warn "could not resolve delta version; skipping"
    return 0
  }
  case "$ARCH" in
    amd64) __sb_arch=amd64 ;;
    arm64) __sb_arch=arm64 ;;
    *)
      warn "no delta build for arch $ARCH; skipping"
      return 0
      ;;
  esac
  __sb_url="https://github.com/dandavison/delta/releases/download/${__sb_ver}/git-delta_${__sb_ver}_${__sb_arch}.deb"
  log "Installing git-delta $__sb_ver ($__sb_arch)"
  install_deb "$__sb_url"
}
