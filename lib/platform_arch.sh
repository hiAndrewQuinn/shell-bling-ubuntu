#!/bin/sh
# Experimental: Arch Linux support. pacman handles most tools directly;
# per-tool installers in lib/tools/* fill the gaps. AUR is intentionally not
# used — keep the install snap-free AND AUR-free so it works on a vanilla
# pacman without needing yay/paru. Anything AUR-only falls through to the
# GitHub release path.

platform_arch_universal_pkgs() {
  # Arch package names. Anything in the registry (lib/registry.sh) is
  # excluded — the registry installs the upstream binary directly,
  # giving Arch users the same version as every other distro.
  echo "fish curl git vim tmux tree htop kitty xclip \
        gcc make nodejs unzip xz \
        helix fzf"
}
