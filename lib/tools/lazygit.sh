#!/bin/sh
# Install lazygit from GitHub releases. Arch-aware.

install_lazygit() {
  has_cmd lazygit && return 0
  case "$DISTRO" in
    macos)
      brew install lazygit
      return $?
      ;;
    fedora) pkg_install lazygit && has_cmd lazygit && return 0 ;;
  esac

  _ver=$(github_latest_tag jesseduffield/lazygit)
  [ -n "$_ver" ] || {
    err "could not resolve lazygit version"
    return 1
  }

  case "$ARCH" in
    amd64) _suffix=Linux_x86_64 ;;
    arm64) _suffix=Linux_arm64 ;;
    *)
      err "no lazygit build for arch $ARCH"
      return 1
      ;;
  esac

  _url="https://github.com/jesseduffield/lazygit/releases/download/v${_ver}/lazygit_${_ver}_${_suffix}.tar.gz"
  _tmp=$(mktemp -d)
  log "Installing lazygit $_ver ($_suffix)"
  fetch_to "$_url" "$_tmp/lazygit.tar.gz" || {
    rm -rf "$_tmp"
    return 1
  }
  tar -xzf "$_tmp/lazygit.tar.gz" -C "$_tmp" lazygit
  sudo_run install -m 0755 "$_tmp/lazygit" /usr/local/bin/lazygit
  rm -rf "$_tmp"
}
