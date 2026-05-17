#!/bin/sh
# Post-install hook for helix (registered in lib/registry.sh).
# The engine has already installed `hx` to /usr/local/bin/hx; helix's binary
# also needs its `runtime/` directory at /usr/local/share/helix/runtime/
# (or pointed at via the HELIX_RUNTIME env var) — without it, syntax
# highlighting, themes, and tree-sitter grammars are all missing.

helix_postinstall() {
  # Top-level dir inside the tarball is helix-{ver}-{arch}-linux/. The
  # registry already gave us the per-arch BIN_IN_ARCHIVE; the runtime/
  # lives next to the hx binary in that same directory.
  _topdir=$(printf '%s' "$(_reg_bin_in_archive "$REGISTRY_TOOL")" | cut -d/ -f1)
  if [ -z "$_topdir" ] || [ ! -d "$REGISTRY_TMP_DIR/$_topdir/runtime" ]; then
    warn "helix: runtime/ not found in $REGISTRY_TMP_DIR/$_topdir"
    return 0
  fi
  sudo_run mkdir -p /usr/local/share/helix
  sudo_run rm -rf /usr/local/share/helix/runtime
  sudo_run cp -r "$REGISTRY_TMP_DIR/$_topdir/runtime" \
    /usr/local/share/helix/runtime
}
