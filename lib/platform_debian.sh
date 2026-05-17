#!/bin/sh
# Tier-1: Debian (bookworm/12, trixie/13).
#
# Universal apt list + preflight matches the pattern every other
# platform_*.sh follows. Anything in lib/registry.sh (cheat, eza, gh,
# gopass, lazygit, lsd, micro, neovim, qsv, starship, tealdeer, zoxide)
# is intentionally absent — the registry installs the upstream binary
# directly, giving Debian users the same version as every other distro.

platform_debian_universal_pkgs() {
  # helix is intentionally absent — Debian doesn't ship a `helix` apt
  # package, and one missing name makes apt's transactional install
  # abort the whole batch. The legacy install_helix() in lib/tools/helix.sh
  # handles the upstream tarball install (with the runtime/ dir) instead.
  echo "curl git ca-certificates gnupg unzip xz-utils \
        fish \
        ripgrep jq tmux tree htop \
        bat fd-find xclip lnav gron \
        gcc g++ make nodejs \
        fzf"
}

platform_debian_preflight() {
  # vim-gtk3 only available where a GUI stack is present; fall back to vim.
  pkg_install vim-gtk3 2> /dev/null || pkg_install vim
  # kitty is GUI; not always in minimal containers — graceful skip.
  pkg_install kitty 2> /dev/null || warn "kitty unavailable; skipping"
}
