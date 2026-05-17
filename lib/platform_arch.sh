#!/bin/sh
# Experimental: Arch Linux support. pacman handles most tools directly;
# per-tool installers in lib/tools/* fill the gaps. AUR is intentionally not
# used — keep the install snap-free AND AUR-free so it works on a vanilla
# pacman without needing yay/paru. Anything AUR-only falls through to the
# GitHub release path.

platform_arch_universal_pkgs() {
  # Arch package names. Mostly the upstream binary name; a few exceptions:
  #   github-cli → /usr/bin/gh ; tealdeer → /usr/bin/tldr
  echo "fish curl git ripgrep jq vim tmux tree htop bat fd kitty xclip \
        gcc make nodejs git-delta lnav micro unzip xz gron \
        lsd neovim eza github-cli starship zoxide tealdeer gopass \
        lazygit"
}
