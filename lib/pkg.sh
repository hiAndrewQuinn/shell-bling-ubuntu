#!/bin/sh
# Package-manager abstraction. Requires DISTRO/OS_FAMILY from lib/detect.sh.
# All commands assume non-interactive use (no prompts).

has_cmd() {
  command -v "$1" > /dev/null 2>&1
}

log() {
  printf '\033[36m==>\033[0m %s\n' "$*"
}

warn() {
  printf '\033[33m==> WARN:\033[0m %s\n' "$*" >&2
}

err() {
  printf '\033[31m==> ERROR:\033[0m %s\n' "$*" >&2
}

# sudo_run CMD [ARG...] — run as root when needed; pass-through if already root.
sudo_run() {
  if [ "$(id -u 2> /dev/null || echo 0)" = 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

# Cache of "we've updated the index this session"
_PKG_UPDATED=0

pkg_update() {
  [ "$_PKG_UPDATED" = 1 ] && return 0
  case "$DISTRO" in
    ubuntu | debian)
      sudo_run env DEBIAN_FRONTEND=noninteractive apt-get update -y
      ;;
    fedora)
      sudo_run dnf -y makecache
      ;;
    macos)
      has_cmd brew || _install_homebrew
      brew update
      ;;
    *)
      warn "pkg_update: unknown distro $DISTRO"
      return 1
      ;;
  esac
  _PKG_UPDATED=1
}

# pkg_install pkg1 pkg2 ...
pkg_install() {
  [ "$#" -eq 0 ] && return 0
  pkg_update
  case "$DISTRO" in
    ubuntu | debian)
      sudo_run env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
      ;;
    fedora)
      sudo_run dnf -y install "$@"
      ;;
    macos)
      brew install "$@"
      ;;
    *)
      warn "pkg_install: unknown distro $DISTRO"
      return 1
      ;;
  esac
}

# pkg_available NAME — is the package known to the package manager?
pkg_available() {
  case "$DISTRO" in
    ubuntu | debian) apt-cache show "$1" > /dev/null 2>&1 ;;
    fedora) dnf info "$1" > /dev/null 2>&1 ;;
    macos) brew info --formula "$1" > /dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

_install_homebrew() {
  has_cmd brew && return 0
  log "Installing Homebrew (non-interactive)"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # PATH for brew on Apple Silicon / Intel
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

# fetch_to URL DEST — download with curl, with retries, atomic move.
# Uses __sb_ prefixed locals to avoid clobbering caller's $_tmp (no `local` in POSIX).
fetch_to() {
  __sb_url=$1
  __sb_dest=$2
  __sb_part="${__sb_dest}.part.$$"
  curl --fail --silent --show-error --location \
    --retry 3 --retry-delay 2 --connect-timeout 15 \
    -o "$__sb_part" "$__sb_url" || {
    rm -f "$__sb_part"
    err "Download failed: $__sb_url"
    return 1
  }
  mv -f "$__sb_part" "$__sb_dest"
}

# install_deb URL — download a .deb and install via apt to resolve deps.
install_deb() {
  case "$DISTRO" in
    ubuntu | debian) ;;
    *)
      warn "install_deb only valid on ubuntu/debian"
      return 1
      ;;
  esac
  _tmp=$(mktemp --suffix=.deb)
  fetch_to "$1" "$_tmp" || {
    rm -f "$_tmp"
    return 1
  }
  sudo_run env DEBIAN_FRONTEND=noninteractive apt-get install -y "$_tmp"
  _rc=$?
  rm -f "$_tmp"
  return "$_rc"
}

# github_latest_tag OWNER/REPO — print the latest release tag (strips leading v).
github_latest_tag() {
  curl --fail --silent --show-error --location \
    --retry 3 --retry-delay 2 \
    "https://api.github.com/repos/$1/releases/latest" |
    sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p' |
    head -n 1
}
