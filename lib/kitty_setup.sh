#!/bin/sh
# Kitty config + FiraCode Nerd Font. Idempotent.

# ----- FiraCode Nerd Font pin -----
#
# We used to fetch this from nerd-fonts/raw/HEAD/patched-fonts/..., which
# follows master and is therefore not a pin at all. Upstream v3.5.0
# (2026-08-02) deleted the patched-fonts/ tree from the repo and now ships
# patched fonts only as release assets, so that URL started 404ing the day
# it landed. Because the font install is deliberately non-fatal, every CI
# lane kept reporting PASS while quietly installing no font for two weeks
# (builds 63-66).
#
# Git tags are immutable, so raw/<tag>/ cannot drift the way raw/HEAD did.
# Same class of bug, and the same fix, as the toybox move off landley.net's
# mutable /bin/ path onto /downloads/binaries/<version>/.
#
# To bump: pick a tag that still carries patched-fonts/ (<= v3.4.0), then
#   curl -sSL "$NERD_FONT_URL" | sha256sum
# and paste the result below. Upstream publishes no per-file checksums for
# the in-tree fonts, so an inline pin is the only verification available —
# but combined with an immutable tag it is enough to detect any change.
NERD_FONTS_TAG=v3.4.0
NERD_FONT_SHA256=2eea93c52a956b1d49604e3cc3215c6314725440bdaf1e4a43b080c5e9719cdd

# _install_nerd_font DEST — fetch + hash-verify the pinned .ttf, then move it
# into place. Returns non-zero on any failure; the caller decides how loud to
# be about it (today: a warning, because a missing font must never break an
# otherwise good install).
_install_nerd_font() {
  __sb_font_dest=$1
  __sb_font_url="https://github.com/ryanoasis/nerd-fonts/raw/${NERD_FONTS_TAG}/patched-fonts/FiraCode/Retina/FiraCodeNerdFont-Retina.ttf"
  __sb_font_part="${__sb_font_dest}.part.$$"

  fetch_to "$__sb_font_url" "$__sb_font_part" || {
    rm -f "$__sb_font_part"
    return 1
  }

  # Same wording as the registry engine's pin check (lib/registry_install.sh)
  # so one grep for "SHA256 MISMATCH" finds every supply-chain surprise.
  __sb_font_actual=$(sha256sum "$__sb_font_part" 2> /dev/null | cut -d' ' -f1)
  if [ -z "$__sb_font_actual" ]; then
    err "  FiraCode Nerd Font: sha256sum unavailable — cannot verify pin"
    rm -f "$__sb_font_part"
    return 1
  fi
  if [ "$__sb_font_actual" != "$NERD_FONT_SHA256" ]; then
    err "  FiraCode Nerd Font: SHA256 MISMATCH"
    err "    expected: $NERD_FONT_SHA256"
    err "    got:      $__sb_font_actual"
    rm -f "$__sb_font_part"
    return 1
  fi
  log "  FiraCode Nerd Font: sha256 ✓"

  mv -f "$__sb_font_part" "$__sb_font_dest"
}

setup_kitty() {
  # Font: only on systems where we have a place to drop it.
  if [ "$OS_FAMILY" = linux ] && [ "$IS_WSL" = 0 ]; then
    mkdir -p "$HOME/.local/share/fonts"
    _font="$HOME/.local/share/fonts/FiraCodeNerdFont-Retina.ttf"
    if [ ! -f "$_font" ]; then
      log "Installing FiraCode Nerd Font"
      _install_nerd_font "$_font" || warn "font install failed; continuing"
      has_cmd fc-cache && fc-cache -f > /dev/null 2>&1 || true
    fi
  fi

  # kitty.conf
  if has_cmd kitty; then
    mkdir -p "$HOME/.config/kitty"
    _conf="$HOME/.config/kitty/kitty.conf"
    if [ ! -f "$_conf" ]; then
      kitty +runpy 'from kitty.config import commented_out_default_config; print(commented_out_default_config())' \
        > "$_conf" 2> /dev/null || : > "$_conf"
    fi
    # Idempotent: only set if not already present uncommented.
    if ! grep -qE '^font_family\s+FiraCode' "$_conf"; then
      sed -i.bak 's/^# *font_family .*/font_family    FiraCode Nerd Font/' "$_conf" || true
      grep -qE '^font_family\s+FiraCode' "$_conf" ||
        printf '\nfont_family    FiraCode Nerd Font\n' >> "$_conf"
    fi
    if ! grep -qE '^disable_ligatures\s+never' "$_conf"; then
      sed -i.bak 's/^# *disable_ligatures .*/disable_ligatures     never/' "$_conf" || true
      grep -qE '^disable_ligatures\s+never' "$_conf" ||
        printf 'disable_ligatures     never\n' >> "$_conf"
    fi
    rm -f "$_conf.bak"
  fi

  # Default terminal alternative — Linux desktop only.
  # --install registers kitty as a candidate; --set actually makes it
  # the active default. Without --set, the highest-priority *automatic*
  # candidate wins, which on Debian GNOME is usually gnome-terminal.
  if [ "$OS_FAMILY" = linux ] && [ "$IS_WSL" = 0 ] && has_cmd update-alternatives && has_cmd kitty; then
    _kitty_bin=$(command -v kitty)
    sudo_run update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator \
      "$_kitty_bin" 50 > /dev/null 2>&1 || true
    sudo_run update-alternatives --set x-terminal-emulator "$_kitty_bin" > /dev/null 2>&1 || true
    unset _kitty_bin
  fi
}
