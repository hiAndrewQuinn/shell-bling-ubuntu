#!/bin/sh
# Detect host platform. Exports:
#   OS_FAMILY   - linux | darwin
#   DISTRO      - ubuntu | debian | fedora | macos | unknown
#   CODENAME    - e.g. noble, bookworm, ""  (empty on macos)
#   VERSION_ID  - e.g. 24.04, 13, 39
#   ARCH        - amd64 | arm64 | unknown
#   IS_WSL      - 1 | 0
#   SUPPORT_TIER - tier1 | experimental | unsupported

OS_FAMILY=unknown
DISTRO=unknown
CODENAME=""
VERSION_ID=""
ARCH=unknown
IS_WSL=0
SUPPORT_TIER=unsupported

_uname_s=$(uname -s 2> /dev/null || echo unknown)
case "$_uname_s" in
  Linux) OS_FAMILY=linux ;;
  Darwin) OS_FAMILY=darwin ;;
esac

_uname_m=$(uname -m 2> /dev/null || echo unknown)
case "$_uname_m" in
  x86_64 | amd64) ARCH=amd64 ;;
  aarch64 | arm64) ARCH=arm64 ;;
esac

if [ "$OS_FAMILY" = linux ] && [ -r /proc/version ]; then
  if grep -qiE 'microsoft|wsl' /proc/version 2> /dev/null; then
    IS_WSL=1
  fi
fi

if [ "$OS_FAMILY" = darwin ]; then
  DISTRO=macos
  VERSION_ID=$(sw_vers -productVersion 2> /dev/null || echo "")
elif [ -r /etc/os-release ]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  DISTRO=${ID:-unknown}
  CODENAME=${VERSION_CODENAME:-}
  VERSION_ID=${VERSION_ID:-}
  # Normalize SUSE family: ID is "opensuse-tumbleweed" or "opensuse-leap", but
  # every per-tool installer just wants "opensuse". Stash the original in
  # CODENAME so callers can still distinguish if they need to.
  case "$DISTRO" in
    opensuse-tumbleweed)
      DISTRO=opensuse
      CODENAME=tumbleweed
      ;;
    opensuse-leap)
      DISTRO=opensuse
      CODENAME=leap
      ;;
  esac
fi

case "$DISTRO:$CODENAME" in
  ubuntu:jammy | ubuntu:noble | ubuntu:oracular | ubuntu:plucky | ubuntu:questing | ubuntu:resolute)
    SUPPORT_TIER=tier1
    ;;
  debian:bookworm | debian:trixie)
    SUPPORT_TIER=tier1
    ;;
  fedora:* | macos:* | arch:* | alpine:* | opensuse:*)
    SUPPORT_TIER=experimental
    ;;
esac

# WSL piggybacks on the underlying ubuntu/debian tier but is experimental
# overall because of GUI bits.
if [ "$IS_WSL" = 1 ]; then
  SUPPORT_TIER=experimental
fi

export OS_FAMILY DISTRO CODENAME VERSION_ID ARCH IS_WSL SUPPORT_TIER

detect_print_summary() {
  printf 'OS family:    %s\n' "$OS_FAMILY"
  printf 'Distro:       %s %s (%s)\n' "$DISTRO" "$VERSION_ID" "$CODENAME"
  printf 'Architecture: %s\n' "$ARCH"
  printf 'WSL:          %s\n' "$IS_WSL"
  printf 'Support tier: %s\n' "$SUPPORT_TIER"
}
