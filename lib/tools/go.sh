#!/bin/sh
# Install the official Go toolchain from go.dev. Lands at /usr/local/go;
# binaries (go, gofmt) at /usr/local/go/bin/. PATH wiring lives in
# lib/fish_setup.sh.

install_go() {
  has_cmd go && return 0
  case "$DISTRO" in
    macos)
      brew install go
      return $?
      ;;
  esac

  case "$ARCH" in
    amd64) _go_arch=amd64 ;;
    arm64) _go_arch=arm64 ;;
    *)
      warn "no Go tarball for arch $ARCH; skipping"
      return 0
      ;;
  esac

  _ver=$(curl -fsSL 'https://go.dev/VERSION?m=text' 2> /dev/null | head -n1)
  case "$_ver" in
    go*) ;;
    *)
      warn "could not resolve Go version (got '$_ver'); skipping"
      return 0
      ;;
  esac

  _url="https://go.dev/dl/${_ver}.linux-${_go_arch}.tar.gz"
  _tmp=$(mktemp -d)
  log "Installing Go $_ver (linux-${_go_arch})"
  if ! fetch_to "$_url" "$_tmp/go.tar.gz"; then
    rm -rf "$_tmp"
    return 1
  fi
  sudo_run rm -rf /usr/local/go
  sudo_run tar -C /usr/local -xzf "$_tmp/go.tar.gz"
  rm -rf "$_tmp"
}
