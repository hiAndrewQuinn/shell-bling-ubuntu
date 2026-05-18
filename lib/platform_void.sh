#!/bin/sh
# Experimental: Void Linux support. xbps package manager, both glibc and
# musl variants exist (separate images). The `latest-full-x86_64` image
# is glibc; musl is `latest-full-x86_64-musl` (not yet in the test matrix).
#
# xbps is a non-strict, BSD-influenced package manager — closer in
# behavior to dnf --setopt=strict=0 than to apk's aborting batch mode.
# Anything in lib/registry.sh is intentionally absent — the registry
# installs the upstream binary directly.

platform_void_universal_pkgs() {
  # Void's package names are mostly familiar. xclip + wl-clipboard are
  # in main; kitty is GUI and not always sensible in a container.
  # `coreutils-doc` is split-out — we just want plain coreutils.
  echo "curl git vim tmux tree htop xclip wl-clipboard \
        sqlite rsync tar \
        zstd lz4 xxhash \
        gcc make nodejs unzip xz \
        kitty-terminfo \
       "
}

platform_void_preflight() {
  # Void's mirror needs `xbps-install -S` to sync the repo index before
  # any install. pkg_update handles this; preflight is otherwise a no-op.
  :
}

# Empty for now — fill in as the test matrix surfaces specific failures.
platform_void_known_unavailable() {
  :
}
