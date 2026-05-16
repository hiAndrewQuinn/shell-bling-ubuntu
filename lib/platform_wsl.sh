#!/bin/sh
# Experimental: WSL2 quirks. Same install path as native Ubuntu/Debian,
# but skip GUI bits.

platform_wsl_preflight() {
  warn "WSL detected — skipping GUI font install and kitty alternative"
  warn "If you want kitty on Windows, install via your Windows host instead"
}
