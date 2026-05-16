#!/bin/sh
# Install Helix from GitHub release tarball (no snap).

install_helix() {
  has_cmd hx && return 0
  case "$DISTRO" in
    macos)
      brew install helix
      return $?
      ;;
    fedora) pkg_install helix && return 0 ;;
  esac
  # Debian 13+ / Ubuntu 24.04+ have helix in apt.
  if pkg_available helix; then
    pkg_install helix && return 0
  fi

  _ver=$(github_latest_tag helix-editor/helix)
  [ -n "$_ver" ] || {
    err "could not resolve helix version"
    return 1
  }

  case "$ARCH" in
    amd64) _suffix=x86_64-linux ;;
    arm64) _suffix=aarch64-linux ;;
    *)
      err "no helix build for arch $ARCH"
      return 1
      ;;
  esac

  _url="https://github.com/helix-editor/helix/releases/download/${_ver}/helix-${_ver}-${_suffix}.tar.xz"
  _tmp=$(mktemp -d)
  log "Installing helix $_ver ($_suffix)"
  fetch_to "$_url" "$_tmp/hx.tar.xz" || {
    rm -rf "$_tmp"
    return 1
  }
  if ! tar -xJf "$_tmp/hx.tar.xz" -C "$_tmp" 2> /dev/null; then
    err "helix: tar -xJf failed (is xz installed?)"
    rm -rf "$_tmp"
    return 1
  fi
  _src=$(find "$_tmp" -maxdepth 1 -type d -name 'helix-*' | head -n 1)
  if [ -z "$_src" ] || [ ! -x "$_src/hx" ]; then
    err "helix: extracted tarball missing 'helix-*/hx' (tar succeeded but hx not found)"
    rm -rf "$_tmp"
    return 1
  fi
  sudo_run install -m 0755 "$_src/hx" /usr/local/bin/hx
  sudo_run mkdir -p /usr/local/share/helix
  sudo_run cp -r "$_src/runtime" /usr/local/share/helix/runtime
  rm -rf "$_tmp"
}
