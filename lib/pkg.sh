#!/bin/sh
# Package-manager abstraction. Requires DISTRO/OS_FAMILY from lib/detect.sh.
# All commands assume non-interactive use (no prompts).

has_cmd() {
  command -v "$1" > /dev/null 2>&1
}

# Color vars honor https://no-color.org/ — set NO_COLOR to any non-empty value
# to suppress ANSI escapes everywhere shell-bling prints. Computed once at
# source time so the cost is one fork; consumers just splat the var.
if [ -n "${NO_COLOR-}" ]; then
  _SB_CYAN=''
  _SB_YEL=''
  _SB_RED=''
  _SB_GRN=''
  _SB_BLD_YEL=''
  _SB_BLD_GRN=''
  _SB_RST=''
else
  _SB_CYAN=$(printf '\033[36m')
  _SB_YEL=$(printf '\033[33m')
  _SB_RED=$(printf '\033[31m')
  _SB_GRN=$(printf '\033[32m')
  _SB_BLD_YEL=$(printf '\033[1;33m')
  _SB_BLD_GRN=$(printf '\033[1;32m')
  _SB_RST=$(printf '\033[0m')
fi

log() {
  printf '%s==>%s %s\n' "$_SB_CYAN" "$_SB_RST" "$*"
}

warn() {
  printf '%s==> WARN:%s %s\n' "$_SB_YEL" "$_SB_RST" "$*" >&2
}

err() {
  printf '%s==> ERROR:%s %s\n' "$_SB_RED" "$_SB_RST" "$*" >&2
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
    fedora | rhel)
      # dnf for RHEL 8+ / Fedora / AL2023; yum for the legacy yum-era
      # distros (CentOS 7, Amazon Linux 2). Both accept `makecache`.
      if has_cmd dnf; then
        sudo_run dnf -y makecache
      else
        sudo_run yum -y makecache fast
      fi
      ;;
    arch)
      sudo_run pacman -Sy --noconfirm
      ;;
    alpine)
      sudo_run apk update
      ;;
    opensuse)
      sudo_run zypper --non-interactive refresh
      ;;
    void)
      sudo_run xbps-install -Sy
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
    fedora | rhel)
      # --setopt=strict=0 → skip individual packages that don't exist instead
      # of failing the entire batch. Fedora repos are split across base + RPM
      # Fusion + COPR; RHEL clones split across base + AppStream + EPEL +
      # (Amazon Linux) extras. A single missing package would otherwise
      # abort and leave the rest uninstalled.
      # CentOS 7 and Amazon Linux 2 ship `yum` instead of `dnf`; --skip-broken
      # is yum's equivalent of dnf's --setopt=strict=0.
      if has_cmd dnf; then
        sudo_run dnf -y --setopt=strict=0 install "$@"
      else
        sudo_run yum -y --skip-broken install "$@"
      fi
      ;;
    arch)
      # --needed → skip already-installed; pacman aborts the whole batch on
      # missing packages, so per-tool callers should still post-check with
      # `has_cmd <bin>` before declaring success.
      sudo_run pacman -S --needed --noconfirm "$@"
      ;;
    alpine)
      # `apk add` aborts the batch on any unknown package, so per-tool
      # callers post-check with `has_cmd <bin>`.
      sudo_run apk add --no-cache "$@"
      ;;
    opensuse)
      # zypper exits 104 ("no provider") if any requested package is
      # unknown — and aborts the rest. Install one at a time so a single
      # missing package doesn't strand the batch (same intent as dnf's
      # --setopt=strict=0 and our per-package handling on Alpine).
      __sb_rc=0
      for __sb_p in "$@"; do
        sudo_run zypper --non-interactive install --no-recommends "$__sb_p" || __sb_rc=$?
      done
      return "$__sb_rc"
      ;;
    void)
      # xbps-install exits non-zero per missing package but doesn't
      # abort the whole batch. -y for non-interactive; per-package loop
      # so a single unknown package doesn't poison the return code.
      __sb_rc=0
      for __sb_p in "$@"; do
        sudo_run xbps-install -y "$__sb_p" || __sb_rc=$?
      done
      return "$__sb_rc"
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

# pkg_cleanup — reclaim package-manager scratch space after the install
# phase. apt's /var/cache/apt/archives can hold ~270 MB of unpacked .deb
# files we'll never re-use; dnf/yum similarly cache downloads. Best-effort
# — failures are non-fatal, so we just log a debug-ish warning and
# continue. Called once from install.sh after the apt phase, before the
# fetch phase, so the cleared space is immediately usable for registry
# extraction.
pkg_cleanup() {
  case "$DISTRO" in
    ubuntu | debian)
      sudo_run apt-get clean 2> /dev/null || true
      ;;
    fedora | rhel)
      if has_cmd dnf; then
        sudo_run dnf clean packages 2> /dev/null || true
      else
        sudo_run yum clean packages 2> /dev/null || true
      fi
      ;;
    arch)
      # paccache from pacman-contrib trims old versions; without it,
      # `pacman -Sc --noconfirm` clears the entire cache. We use the
      # safer paccache approach when available.
      if has_cmd paccache; then
        sudo_run paccache -rk0 2> /dev/null || true
      else
        sudo_run pacman -Sc --noconfirm 2> /dev/null || true
      fi
      ;;
    alpine)
      # apk's --no-cache flag in pkg_install means no cache to clean.
      :
      ;;
    opensuse)
      sudo_run zypper --non-interactive clean --all 2> /dev/null || true
      ;;
    void)
      sudo_run xbps-remove -Oo 2> /dev/null || true
      ;;
    macos)
      brew cleanup -s 2> /dev/null || true
      ;;
    *) : ;;
  esac
}

# pkg_available NAME — is the package known to the package manager?
pkg_available() {
  case "$DISTRO" in
    ubuntu | debian) apt-cache show "$1" > /dev/null 2>&1 ;;
    fedora | rhel)
      if has_cmd dnf; then
        dnf info "$1" > /dev/null 2>&1
      else
        yum info "$1" > /dev/null 2>&1
      fi
      ;;
    arch) pacman -Si "$1" > /dev/null 2>&1 ;;
    alpine) apk info -e "$1" > /dev/null 2>&1 || apk search -e "$1" 2> /dev/null | grep -q . ;;
    opensuse) zypper --non-interactive info "$1" 2> /dev/null | grep -q '^Repository' ;;
    void) xbps-query -Rs "$1" 2> /dev/null | grep -q "^\[" ;;
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
# Two strategies, used in order:
#   1. The HTML redirect at github.com/<repo>/releases/latest → /tag/<tag>.
#      Doesn't count against the (60/hour, IP-scoped, unauthenticated)
#      api.github.com rate limit. Survives 403 errors that hit Docker /
#      shared-IP installers in bursts.
#   2. The JSON API at api.github.com/repos/<repo>/releases/latest as
#      a fallback (informative error fields when the redirect strategy
#      breaks for a repo with no formal "latest" release).
github_latest_tag() {
  _tag=$(curl --fail --silent --show-error --location --head \
    --retry 3 --retry-delay 2 \
    -o /dev/null -w '%{url_effective}\n' \
    "https://github.com/$1/releases/latest" 2> /dev/null |
    sed -n 's|.*/releases/tag/v\{0,1\}\(.*\)|\1|p' |
    head -n 1 | tr -d '\r\n')
  if [ -n "$_tag" ]; then
    printf '%s\n' "$_tag"
    return 0
  fi
  curl --fail --silent --show-error --location \
    --retry 3 --retry-delay 2 \
    "https://api.github.com/repos/$1/releases/latest" |
    sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p' |
    head -n 1
}
