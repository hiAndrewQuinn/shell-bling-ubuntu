#!/bin/sh
# Install gopass — modern, pass-compatible password manager.
# Prefer apt where available; fall back to GitHub release tarball.
# Also symlink `pass -> gopass` so existing muscle memory + scripts keep
# working (gopass is drop-in for the `pass` CLI surface).

install_gopass() {
  if has_cmd gopass; then
    _gopass_link_pass
    return 0
  fi
  case "$DISTRO" in
    macos)
      brew install gopass || return $?
      _gopass_link_pass
      return 0
      ;;
    fedora)
      if pkg_install gopass; then
        _gopass_link_pass
        return 0
      fi
      ;;
  esac
  if pkg_available gopass && pkg_install gopass; then
    _gopass_link_pass
    return 0
  fi

  # Binary release fallback (more reliable than the apt repo across distros).
  __sb_ver=$(github_latest_tag gopasspw/gopass)
  [ -n "$__sb_ver" ] || {
    warn "could not resolve gopass version; skipping"
    return 0
  }
  case "$ARCH" in
    amd64) __sb_suffix=linux-amd64 ;;
    arm64) __sb_suffix=linux-arm64 ;;
    *)
      warn "no gopass build for arch $ARCH; skipping"
      return 0
      ;;
  esac
  __sb_url="https://github.com/gopasspw/gopass/releases/download/v${__sb_ver}/gopass-${__sb_ver}-${__sb_suffix}.tar.gz"
  __sb_dir=$(mktemp -d)
  log "Installing gopass $__sb_ver ($__sb_suffix)"
  fetch_to "$__sb_url" "$__sb_dir/gopass.tar.gz" || {
    rm -rf "$__sb_dir"
    return 1
  }
  tar -xzf "$__sb_dir/gopass.tar.gz" -C "$__sb_dir" gopass
  sudo_run install -m 0755 "$__sb_dir/gopass" /usr/local/bin/gopass
  rm -rf "$__sb_dir"
  _gopass_link_pass
}

# gopass is drop-in compatible with `pass`. Skip if /usr/local/bin/pass
# already exists (e.g. real pass installed alongside) to avoid clobbering.
_gopass_link_pass() {
  has_cmd gopass || return 0
  [ -e /usr/local/bin/pass ] && return 0
  case "$DISTRO" in
    macos)
      # Homebrew prefixes vary; just skip — `gopass` is enough on macOS.
      return 0
      ;;
  esac
  # Use an absolute symlink target so the link works regardless of whether
  # gopass landed at /usr/local/bin/gopass (our tarball path) or
  # /usr/bin/gopass (apt path).
  _gopass_path=$(command -v gopass)
  sudo_run ln -s "$_gopass_path" /usr/local/bin/pass 2> /dev/null || true
}
