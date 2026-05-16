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
  curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sudo_run sh > /dev/null
}
