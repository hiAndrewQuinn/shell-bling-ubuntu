#!/bin/sh
# Experimental: Alpine Linux support. musl + busybox + apk. Lean hard on apk:
# most modern dev tools are in alpine community/main, and apk packages link
# against musl correctly. Avoid the GitHub-release path where possible —
# upstream prebuilt binaries are almost universally glibc-only and will
# error with "No such file or directory" (because /lib/ld-linux-* is missing
# on Alpine) when run.

platform_alpine_universal_pkgs() {
  echo "fish bash curl git ca-certificates ripgrep jq vim tmux tree htop \
        bat fd kitty xclip xz unzip micro \
        gcc make nodejs delta lnav \
        lsd eza github-cli starship zoxide gopass \
        helix lazygit fzf neovim shadow sudo"
  # Notes on omissions:
  #   - tealdeer: not packaged on Alpine (cargo install tealdeer if wanted)
  #   - rust/go: glibc-only upstream tarballs; SHELL_BLING_SKIP_TOOLCHAINS=1
  #     users get them via apk (rust + go are in community).
}
