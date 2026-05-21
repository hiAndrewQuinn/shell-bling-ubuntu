#!/bin/sh
# Detect host platform. Exports:
#   OS_FAMILY   - linux | darwin
#   DISTRO      - ubuntu | debian | fedora | macos | unknown
#   CODENAME    - e.g. noble, bookworm, ""  (empty on macos)
#   VERSION_ID  - e.g. 24.04, 13, 39
#   ARCH        - amd64 | arm64 | unknown
#   LIBC        - gnu | musl  (Linux only; "gnu" on macOS by convention)
#   IS_WSL      - 1 | 0
#   SUPPORT_TIER - tier1 | experimental | unsupported

OS_FAMILY=unknown
DISTRO=unknown
CODENAME=""
VERSION_ID=""
ARCH=unknown
LIBC=gnu
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

# libc detection — needed for picking the right upstream-binary asset
# (gnu vs musl) in lib/registry.sh. Alpine's ldd --version prints
# "musl libc (x86_64)..."; glibc's prints a version. Default to gnu so
# macOS / non-Linux hosts don't get caught in the musl branch.
# Also expose GLIBC_VERSION so the registry engine can fall back to musl
# variants when a tool's prebuilt -gnu binary requires a newer glibc than
# the host has (qsv on Debian 12 / Ubuntu 22.04 is the canonical case —
# its -gnu binary needs glibc >= 2.38).
GLIBC_VERSION=""
if [ "$OS_FAMILY" = linux ] && command -v ldd > /dev/null 2>&1; then
  # Keep 2>&1: Alpine's musl ldd writes its banner to stderr, and we rely on
  # seeing "musl libc" to set LIBC=musl. The challenge is that some distros'
  # /usr/bin/ldd is a #!/bin/bash script that prints warnings before the
  # actual version — CentOS 7 with LC_ALL=C.UTF-8 emits "bash: warning:
  # setlocale: cannot change locale (C.UTF-8)" because C.UTF-8 only landed
  # in glibc 2.35. Old positional parsers (head -1 | awk '{print $NF}') would
  # capture "(C.UTF-8)" as the version, fail the numeric gate, and leave
  # GLIBC_VERSION empty — which silently disabled the gnu→musl swap and led
  # to GLIBC_X.Y-not-found crashes downstream. Grep the whole output for the
  # first dotted-numeric token instead; it's robust against arbitrary
  # warning noise from any current or future distro.
  # `|| true` matters: Alpine's ldd exits non-zero on `--version` (it prints
  # usage and returns 1), and busybox ash exits the parent under `set -e`
  # when a command substitution's command fails. Suppress it explicitly.
  _ldd_out=$(ldd --version 2>&1 || true)
  if printf '%s' "$_ldd_out" | grep -qi musl; then
    LIBC=musl
  else
    _v=$(printf '%s' "$_ldd_out" | grep -Eo '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
    case "$_v" in
      [0-9]*.[0-9]*) GLIBC_VERSION=$_v ;;
    esac
  fi
  unset _ldd_out _v
fi
export GLIBC_VERSION

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
    # Normalize the RHEL family: ID varies across Rocky/Alma/CentOS Stream/
    # Amazon Linux but all four use dnf and share enough package names that
    # a single platform_rhel.sh covers them. Original ID kept in CODENAME so
    # per-distro logic (e.g. AL2023's lack of EPEL) can still branch.
    rocky)
      DISTRO=rhel
      CODENAME=rocky
      ;;
    almalinux)
      DISTRO=rhel
      CODENAME=alma
      ;;
    centos)
      DISTRO=rhel
      # CentOS 7 (yum-era, EOL) and CentOS Stream (newer, dnf) both have
      # ID=centos. Disambiguate via major version so platform_rhel.sh can
      # branch on yum-vs-dnf and very-old-glibc.
      case "${VERSION_ID%%.*}" in
        7) CODENAME=centos7 ;;
        *) CODENAME=centos-stream ;;
      esac
      ;;
    amzn)
      DISTRO=rhel
      # AL2 (yum, glibc 2.26) vs AL2023 (dnf, glibc 2.34). Both ID=amzn.
      case "$VERSION_ID" in
        2) CODENAME=amzn-2 ;;
        *) CODENAME=amzn ;;
      esac
      ;;
    # Debian-family derivatives: Kali rolling tracks Debian sid closely.
    # Same apt machinery, same platform_debian.sh — only the ID differs.
    kali)
      DISTRO=debian
      CODENAME=kali-rolling
      ;;
    # Arch-family derivatives: Manjaro tracks Arch with a small delay and
    # its own repos, but pacman and the package names are the same.
    manjaro | manjaro-arm)
      DISTRO=arch
      CODENAME=manjaro
      ;;
  esac
fi

case "$DISTRO:$CODENAME" in
  ubuntu:focal | ubuntu:jammy | ubuntu:noble | ubuntu:oracular | ubuntu:plucky | ubuntu:questing | ubuntu:resolute)
    SUPPORT_TIER=tier1
    ;;
  debian:bullseye | debian:bookworm | debian:trixie | debian:kali-rolling)
    SUPPORT_TIER=tier1
    ;;
  fedora:* | macos:* | arch:* | alpine:* | opensuse:* | rhel:* | void:*)
    SUPPORT_TIER=experimental
    ;;
esac

# WSL piggybacks on the underlying ubuntu/debian tier but is experimental
# overall because of GUI bits.
if [ "$IS_WSL" = 1 ]; then
  SUPPORT_TIER=experimental
fi

export OS_FAMILY DISTRO CODENAME VERSION_ID ARCH LIBC IS_WSL SUPPORT_TIER

detect_print_summary() {
  printf 'OS family:    %s\n' "$OS_FAMILY"
  printf 'Distro:       %s %s (%s)\n' "$DISTRO" "$VERSION_ID" "$CODENAME"
  printf 'Architecture: %s (%s libc)\n' "$ARCH" "$LIBC"
  printf 'WSL:          %s\n' "$IS_WSL"
  printf 'Support tier: %s\n' "$SUPPORT_TIER"
}
