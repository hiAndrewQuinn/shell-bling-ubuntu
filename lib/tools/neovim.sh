#!/bin/sh
# Install latest Neovim. Use distro package where new enough; otherwise the
# official AppImage / Homebrew formula.

install_neovim() {
  has_cmd nvim && return 0
  case "$DISTRO" in
    ubuntu)
      # PPA only works on Ubuntu. Falls back to AppImage if add-apt-repository
      # isn't available (minimal images).
      if has_cmd add-apt-repository || pkg_install software-properties-common; then
        sudo_run add-apt-repository -y ppa:neovim-ppa/unstable || _install_neovim_appimage
        pkg_update
        pkg_install neovim || _install_neovim_appimage
      else
        _install_neovim_appimage
      fi
      ;;
    debian)
      # Backports has a reasonably current nvim on bookworm; trixie ships
      # current. AppImage is the reliable fallback.
      pkg_install neovim 2> /dev/null || _install_neovim_appimage
      ;;
    fedora)
      pkg_install neovim
      ;;
    macos)
      brew install neovim
      ;;
    *) warn "install_neovim: unknown distro" ;;
  esac
}

_install_neovim_appimage() {
  case "$ARCH" in
    amd64) _suffix=linux-x86_64 ;;
    arm64) _suffix=linux-arm64 ;;
    *)
      err "no neovim AppImage for arch $ARCH"
      return 1
      ;;
  esac
  _url="https://github.com/neovim/neovim/releases/latest/download/nvim-${_suffix}.appimage"
  _dest=/usr/local/bin/nvim
  log "Installing Neovim AppImage ($_suffix)"
  _tmp=$(mktemp)
  fetch_to "$_url" "$_tmp" || return 1
  chmod +x "$_tmp"
  sudo_run install -m 0755 "$_tmp" "$_dest"
  rm -f "$_tmp"
}
