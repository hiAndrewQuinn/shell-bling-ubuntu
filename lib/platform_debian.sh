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
        tmux tree htop xclip wl-clipboard \
        sqlite3 rsync \
        zstd lz4 xxhash \
        gcc g++ make nodejs"
}

platform_debian_preflight() {
  # vim-gtk3 only available where a GUI stack is present; fall back to vim.
  pkg_install vim-gtk3 2> /dev/null || pkg_install vim
  # kitty is GUI; not always in minimal containers — graceful skip.
  pkg_install kitty 2> /dev/null || warn "kitty unavailable; skipping"
}

# platform_debian_known_unavailable — tools the engine cannot install on this
# Debian release because every fallback path is exhausted (upstream binary
# needs newer glibc, no musl variant pinned, and the distro package doesn't
# exist or is too old). install.sh prints this as a "Known limitations"
# notice rather than treating the smoke failure as unexpected. Format:
# one "TOOL    one-line reason" per line.
platform_debian_known_unavailable() {
  case "$CODENAME" in
    bullseye)
      printf '%s\n' \
        'helix    upstream tarball needs glibc 2.34+ (Debian 11 has 2.31); no upstream musl build; no apt package in bullseye.' \
        'neovim   upstream tarball needs glibc 2.34+; apt installs nvim 0.4.4 from bullseye instead. LazyVim auto-skipped (needs nvim >= 0.11).'
      ;;
  esac
}
