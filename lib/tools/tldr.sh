#!/bin/sh
# Install tldr (tealdeer when available — fast Rust client).

install_tldr() {
  has_cmd tldr && return 0
  case "$DISTRO" in
    macos)
      brew install tealdeer
      return $?
      ;;
    fedora) pkg_install tealdeer && return 0 ;;
  esac
  if pkg_available tealdeer; then
    pkg_install tealdeer && return 0
  fi
  if pkg_available tldr; then
    pkg_install tldr && return 0
  fi
  warn "no tldr/tealdeer package; skipping (install with cargo if you want it)"
}
