#!/bin/sh
# Tier-1: Debian (bookworm/12, trixie/13).
#
# Universal apt list + preflight matches the pattern every other
# platform_*.sh follows. Anything in lib/registry.sh (cheat, eza, gh,
# gopass, lazygit, lsd, micro, neovim, qsv, starship, tealdeer, zoxide)
# is intentionally absent — the registry installs the upstream binary
# directly, giving Debian users the same version as every other distro.

platform_debian_universal_pkgs() {
  # Everything else (bat, cheat, delta, eza, fd, fzf, gh, gopass, gron,
  # helix, jq, lazygit, lnav, lsd, micro, neovim, qsv, ripgrep, starship,
  # tealdeer, zoxide) ships from lib/registry.sh as a pinned upstream
  # binary — same version across every distro.
  echo "curl git ca-certificates gnupg unzip xz-utils \
        fish \
        tmux tree htop xclip \
        gcc g++ make nodejs"
}

platform_debian_preflight() {
  # vim-gtk3 only available where a GUI stack is present; fall back to vim.
  pkg_install vim-gtk3 2> /dev/null || pkg_install vim
  # kitty is GUI; not always in minimal containers — graceful skip.
  pkg_install kitty 2> /dev/null || warn "kitty unavailable; skipping"
}
