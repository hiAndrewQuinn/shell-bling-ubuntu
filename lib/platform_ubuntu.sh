#!/bin/sh
# Tier-1: Ubuntu (jammy/22.04, noble/24.04, oracular, plucky, questing, resolute/26.04).
#
# Same package set as Debian, plus `software-properties-common` so the
# `add-apt-repository` helper is available (some downstream tools or
# documentation still recommend PPAs even though shell-bling itself avoids
# them). Anything in lib/registry.sh is intentionally absent — the
# registry installs the upstream binary directly.

platform_ubuntu_universal_pkgs() {
  # Same shape as Debian; everything else lives in lib/registry.sh.
  echo "curl git ca-certificates gnupg unzip xz-utils \
        tmux tree htop xclip wl-clipboard \
        sqlite3 rsync \
        gcc g++ make nodejs"
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

# Same shape as platform_debian_known_unavailable — see that function's
# header comment in lib/platform_debian.sh for the contract.
platform_ubuntu_known_unavailable() {
  case "$CODENAME" in
    focal)
      printf '%s\n' \
        'helix    upstream tarball needs glibc 2.34+ (Ubuntu 20.04 has 2.31); no upstream musl build; no apt package in focal.' \
        'neovim   upstream tarball needs glibc 2.34+; apt installs an older nvim from focal instead. LazyVim auto-skipped (needs nvim >= 0.11).'
      ;;
  esac
}
