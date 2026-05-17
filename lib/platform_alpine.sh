#!/bin/sh
# Experimental: Alpine Linux support. musl + busybox + apk. Lean hard on apk:
# most modern dev tools are in alpine community/main, and apk packages link
# against musl correctly. Avoid the GitHub-release path where possible —
# upstream prebuilt binaries are almost universally glibc-only and will
# error with "No such file or directory" (because /lib/ld-linux-* is missing
# on Alpine) when run.

platform_alpine_universal_pkgs() {
  echo "fish bash curl git ca-certificates vim tmux tree htop \
        kitty xclip xz unzip \
        gcc make nodejs \
        neovim shadow sudo"
  # Notes:
  #   - The registry (lib/registry.sh) installs every other tool from the
  #     upstream binary directly (musl variants where required); the
  #     pkg_install fallback covers gaps.
  #   - neovim stays in apt because its upstream tarball is glibc-only; on
  #     Alpine apk's neovim is the right binary anyway (musl-linked).
  #   - gron has no Alpine apk; the registry's gron entry uses the Go-static
  #     amd64/arm64 tarball, which runs on musl too.
}
