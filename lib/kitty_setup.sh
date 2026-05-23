#!/bin/sh
# Kitty config + FiraCode Nerd Font. Idempotent.

setup_kitty() {
  # Font: only on systems where we have a place to drop it.
  if [ "$OS_FAMILY" = linux ] && [ "$IS_WSL" = 0 ]; then
    mkdir -p "$HOME/.local/share/fonts"
    _font="$HOME/.local/share/fonts/FiraCodeNerdFont-Retina.ttf"
    if [ ! -f "$_font" ]; then
      log "Installing FiraCode Nerd Font"
      fetch_to \
        "https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/FiraCode/Retina/FiraCodeNerdFont-Retina.ttf" \
        "$_font" || warn "font install failed; continuing"
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
