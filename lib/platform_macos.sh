#!/bin/sh
# Experimental: macOS support via Homebrew.

platform_macos_universal_pkgs() {
  # macOS Homebrew names. Anything in the registry (lib/registry.sh) is
  # excluded — the registry installs the upstream binary directly (macOS
  # URLs to be added in a future round; right now macOS leans more on
  # Homebrew than the registry).
  echo "curl git ripgrep jq vim tmux tree htop bat fd kitty \
        sqlite rsync \
        gcc make node git-delta lnav"
}

platform_macos_preflight() {
  _install_homebrew
}
