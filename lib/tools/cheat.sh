#!/bin/sh
# Install cheat — interactive cheatsheets. Single static binary from GitHub.

install_cheat() {
  has_cmd cheat && return 0
  case "$DISTRO" in
    macos)
      brew install cheat
      return $?
      ;;
  esac

  _ver=$(github_latest_tag cheat/cheat)
  [ -n "$_ver" ] || {
    warn "could not resolve cheat version; skipping"
    return 0
  }

  case "$ARCH" in
    amd64) _suffix=linux-amd64 ;;
    arm64) _suffix=linux-arm64 ;;
    *)
      warn "no cheat build for arch $ARCH; skipping"
      return 0
      ;;
  esac

  _url="https://github.com/cheat/cheat/releases/download/${_ver}/cheat-${_suffix}.gz"
  _tmp=$(mktemp)
  log "Installing cheat $_ver ($_suffix)"
  fetch_to "$_url" "${_tmp}.gz" || return 1
  gunzip -f "${_tmp}.gz"
  sudo_run install -m 0755 "$_tmp" /usr/local/bin/cheat
  rm -f "$_tmp"
}
