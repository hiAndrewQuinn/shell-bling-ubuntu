#!/bin/sh
# Install tldr (tealdeer when available — fast Rust client) and prime the
# cache so the first invocation works offline-ish.

install_tldr() {
  if has_cmd tldr; then
    _tldr_prime_cache
    return 0
  fi
  case "$DISTRO" in
    macos)
      brew install tealdeer || return $?
      _tldr_prime_cache
      return 0
      ;;
    fedora)
      if pkg_install tealdeer; then
        _tldr_prime_cache
        return 0
      fi
      ;;
  esac
  if pkg_available tealdeer && pkg_install tealdeer; then
    _tldr_prime_cache
    return 0
  fi
  if pkg_available tldr && pkg_install tldr; then
    _tldr_prime_cache
    return 0
  fi
  warn "no tldr/tealdeer package; skipping (install with cargo if you want it)"
}

# Best-effort: prime the cache so `tldr fd` works on the first try after
# install. Don't fail the installer if we can't reach the index.
_tldr_prime_cache() {
  has_cmd tldr || return 0
  log "Priming tldr cache"
  tldr --update > /dev/null 2>&1 || warn "tldr cache update failed (you can run 'tldr --update' later)"
}
