#!/bin/sh
# Experimental: Fedora support. Most tools work via dnf or via the binary
# installers in lib/tools/*. This file holds Fedora-specific glue.

platform_fedora_universal_pkgs() {
  # Fedora package names. Some differ from Debian.
  # Only packages that exist in the default Fedora repos go here. Anything
  # COPR-only or missing entirely (gron, cheat, micro on some versions) is
  # handled by the per-tool installers in lib/tools/*. Toolchains
  # (rustup, golang) are installed separately by their own lib/tools scripts.
  echo "fish curl git ripgrep jq vim tmux tree htop bat fd-find kitty xclip \
        gcc gcc-c++ make nodejs git-delta lnav unzip xz micro \
        lsd eza gh starship zoxide tealdeer gopass"
}
