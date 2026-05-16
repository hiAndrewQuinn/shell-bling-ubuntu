#!/bin/sh
# Install latest stable Neovim. On linux we always use the official GitHub
# release tarball — distro packages lag (Debian 13 ships 0.10.x, Fedora 40
# ships 0.10.2; LazyVim needs >=0.11). On macOS, Homebrew is always current.

install_neovim() {
  has_cmd nvim && return 0
  case "$DISTRO" in
    macos)
      brew install neovim
      return $?
      ;;
  esac

  case "$ARCH" in
    amd64) _suffix=linux-x86_64 ;;
    arm64) _suffix=linux-arm64 ;;
    *)
      err "no neovim release tarball for arch $ARCH"
      return 1
      ;;
  esac

  _url="https://github.com/neovim/neovim/releases/latest/download/nvim-${_suffix}.tar.gz"
  _tmp=$(mktemp -d)
  log "Installing Neovim (latest, $_suffix)"
  if ! fetch_to "$_url" "$_tmp/nvim.tar.gz"; then
    rm -rf "$_tmp"
    return 1
  fi
  tar -xzf "$_tmp/nvim.tar.gz" -C "$_tmp"
  # Tarball top-level is nvim-${_suffix}/{bin,lib,share}.
  sudo_run rm -rf /usr/local/nvim
  sudo_run mv "$_tmp/nvim-${_suffix}" /usr/local/nvim
  sudo_run ln -sf /usr/local/nvim/bin/nvim /usr/local/bin/nvim
  rm -rf "$_tmp"
}
