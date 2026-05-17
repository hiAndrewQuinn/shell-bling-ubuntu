#!/bin/sh
# Install micro — small, easy CLI editor. Most distros package it; openSUSE
# Tumbleweed does not, so we fall back to the upstream static binary release.

install_micro() {
  has_cmd micro && return 0
  case "$DISTRO" in
    macos)
      brew install micro
      return $?
      ;;
  esac
  # Most distros: package manager. Fedora/Arch/Alpine/Debian/Ubuntu all
  # carry micro under the name "micro" — its install was handled by the
  # universal-pkg step. Re-check here as a defensive no-op for those.
  if pkg_available micro; then
    pkg_install micro && has_cmd micro && return 0
  fi

  case "$ARCH" in
    amd64) _suffix=linux64-static ;;
    arm64) _suffix=linuxarm64 ;;
    *)
      warn "no micro build for arch $ARCH; skipping"
      return 0
      ;;
  esac

  _ver=$(github_latest_tag zyedidia/micro)
  [ -n "$_ver" ] || {
    warn "could not resolve micro version; skipping"
    return 0
  }
  _url="https://github.com/zyedidia/micro/releases/download/v${_ver}/micro-${_ver}-${_suffix}.tar.gz"
  _tmp=$(mktemp -d)
  log "Installing micro $_ver ($_suffix)"
  if ! fetch_to "$_url" "$_tmp/micro.tar.gz"; then
    rm -rf "$_tmp"
    return 1
  fi
  if ! tar -xzf "$_tmp/micro.tar.gz" -C "$_tmp" 2> /dev/null; then
    err "micro: tar -xzf failed"
    rm -rf "$_tmp"
    return 1
  fi
  _src=$(find "$_tmp" -maxdepth 2 -type f -name micro -perm -u+x | head -n 1)
  if [ -z "$_src" ]; then
    err "micro: extracted tarball missing 'micro' binary"
    rm -rf "$_tmp"
    return 1
  fi
  sudo_run install -m 0755 "$_src" /usr/local/bin/micro
  rm -rf "$_tmp"
}
