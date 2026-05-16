#!/bin/sh
# Install uv (astral) — Python package manager.

install_uv() {
  has_cmd uv && return 0
  case "$DISTRO" in
    macos)
      brew install uv
      return $?
      ;;
  esac
  log "Installing uv"
  __sb_uv_tmp=$(mktemp -d)
  curl -LsSf https://astral.sh/uv/install.sh -o "$__sb_uv_tmp/uv-install.sh"
  # uv's installer respects UV_INSTALL_DIR. Drop into /usr/local/bin via sudo.
  UV_UNMANAGED_INSTALL=/usr/local/bin sudo_run sh "$__sb_uv_tmp/uv-install.sh" > /dev/null
  rm -rf "$__sb_uv_tmp"
}
