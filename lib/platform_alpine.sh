#!/bin/sh
# Experimental: Alpine Linux support. musl + busybox + apk. Lean hard on apk:
# most modern dev tools are in alpine community/main, and apk packages link
# against musl correctly. Avoid the GitHub-release path where possible —
# upstream prebuilt binaries are almost universally glibc-only and will
# error with "No such file or directory" (because /lib/ld-linux-* is missing
# on Alpine) when run.

platform_alpine_universal_pkgs() {
  echo "fish bash curl git ca-certificates ripgrep jq vim tmux tree htop \
        bat fd kitty xclip xz unzip \
        gcc make nodejs lnav delta \
        helix fzf neovim shadow sudo"
  # Notes:
  #   - cheat, eza, gh, gopass, lazygit, lsd, micro, qsv, starship, tealdeer,
  #     zoxide: lib/registry.sh installs the upstream binary directly (works
  #     on musl). The registry's pkg_install fallback covers what little
  #     doesn't have an upstream Linux binary.
  #   - delta, helix, fzf: still legacy lib/tools/* in R4.2 transition; move
  #     to registry once their post-install hooks land.
  #   - neovim stays in apt because its upstream tarball is glibc-only; on
  #     Alpine apk's neovim is the right binary anyway.
  #   - gron: not in Alpine repos. Skipped on this distro.
}
