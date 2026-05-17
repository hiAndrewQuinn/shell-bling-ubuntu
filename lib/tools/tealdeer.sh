#!/bin/sh
# Post-install hook for tealdeer (registered in lib/registry.sh).
# Called by lib/registry_install.sh after the static binary lands at
# /usr/local/bin/tldr. Primes the cache so `tldr fd` works the first time
# without a hidden network round-trip; failure is non-fatal.

tealdeer_postinstall() {
  has_cmd tldr || return 0
  log "Priming tldr cache"
  tldr --update > /dev/null 2>&1 ||
    warn "tldr cache update failed (you can run 'tldr --update' later)"
}
