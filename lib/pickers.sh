#!/bin/sh
# Final interactive fzf pickers. Skipped entirely when
# SHELL_BLING_NONINTERACTIVE=1 (Docker tests, CI, etc.).

run_pickers() {
  if [ "${SHELL_BLING_NONINTERACTIVE:-0}" = 1 ]; then
    log "Non-interactive mode; defaulting EDITOR to nvim, chsh-ing to fish"
    fish_set_editor nvim
    _chsh_to_fish
    return 0
  fi
  if ! has_cmd fzf; then
    warn "fzf not available; skipping pickers"
    return 0
  fi
  _pick_editor
  _pick_shell
}

# Idempotent chsh to fish. Used by both the non-interactive path and the
# interactive "yes" branch. Ensures /etc/shells lists fish first.
_chsh_to_fish() {
  has_cmd fish || return 0
  has_cmd chsh || {
    warn "chsh not available; skipping login shell switch"
    return 0
  }
  _fish=$(command -v fish)
  # Ensure fish is a registered login shell.
  if ! grep -qxF "$_fish" /etc/shells 2> /dev/null; then
    printf '%s\n' "$_fish" | sudo_run tee -a /etc/shells > /dev/null || true
  fi
  # Skip if already set.
  _user=${USER:-$(id -un)}
  _current=$(getent passwd "$_user" 2> /dev/null | cut -d: -f7)
  if [ "$_current" = "$_fish" ]; then
    log "Login shell already $_fish"
    return 0
  fi
  if sudo_run chsh -s "$_fish" "$_user"; then
    log "Login shell set to $_fish"
  else
    warn "chsh -s $_fish $_user failed; run it manually"
  fi
}

_pick_editor() {
  _choices='nvim    # 💯 Latest and greatest.   📈 High learning curve.
vim     # 🥷 The original.          📈 High learning curve.
hx      # 🧬 An elegant weapon.     🕴️ Fun learning curve.
micro   # 🕊️ Easy to use.           📉 Low learning curve.'

  _selected=$(printf '%s\n' "$_choices" |
    fzf --height=40% --reverse \
      --header="Pick your default text editor ✍️" ||
    true)

  if [ -z "$_selected" ]; then
    warn "No editor selected; leaving EDITOR unset"
    return 0
  fi
  _editor=$(printf '%s' "$_selected" | awk '{print $1}')
  if ! has_cmd "$_editor"; then
    warn "$_editor is not installed; leaving EDITOR unset"
    return 0
  fi
  fish_set_editor "$_editor"
  log "Default editor set to $_editor"
}

_pick_shell() {
  has_cmd fish || return 0
  has_cmd chsh || return 0
  # Already fish? Done.
  case "${SHELL:-}" in
    */fish) return 0 ;;
  esac

  _choice=$(printf 'yes — make fish my login shell\nno — keep current shell\n' |
    fzf --height=20% --reverse \
      --header="Switch login shell to fish?" ||
    true)
  case "$_choice" in
    yes*) _chsh_to_fish ;;
    *) log "Leaving login shell unchanged" ;;
  esac
}
