#!/bin/sh
# Tier-1: Ubuntu (jammy/22.04, noble/24.04, oracular, plucky, questing, resolute/26.04).
#
# Same package set as Debian, plus `software-properties-common` so the
# `add-apt-repository` helper is available (some downstream tools or
# documentation still recommend PPAs even though shell-bling itself avoids
# them). Anything in lib/registry.sh is intentionally absent — the
# registry installs the upstream binary directly.

platform_ubuntu_universal_pkgs() {
  # helix is intentionally absent — Ubuntu doesn't ship a `helix` apt
  # package on tier-1 versions (jammy/noble/oracular). The legacy
  # install_helix() in lib/tools/helix.sh handles the upstream tarball
  # install (with the runtime/ dir) instead.
  echo "curl git ca-certificates gnupg unzip xz-utils \
        fish \
        tmux tree htop xclip \
        gcc g++ make nodejs \
        fzf"
}

platform_ubuntu_preflight() {
  # vim-gtk3 only available where a GUI stack is present; fall back to vim.
  pkg_install vim-gtk3 2> /dev/null || pkg_install vim
  # kitty is GUI; not always in minimal containers — graceful skip.
  pkg_install kitty 2> /dev/null || warn "kitty unavailable; skipping"
  # Ubuntu-only: PPA helper. Not required by shell-bling itself but a
  # genuinely useful preinstall on Ubuntu — many third-party tutorials
  # assume `add-apt-repository` works out of the box.
  pkg_install software-properties-common 2> /dev/null || true
}
