#!/bin/sh
# Experimental: Fedora support. Most tools work via dnf or via the binary
# installers in lib/tools/*. This file holds Fedora-specific glue.

platform_fedora_universal_pkgs() {
  # Fedora package names. Anything in the registry (lib/registry.sh) is
  # excluded — the registry installs the upstream binary directly.
  echo "curl git vim tmux tree htop kitty xclip \
        gcc gcc-c++ make nodejs unzip xz \
       "
}
