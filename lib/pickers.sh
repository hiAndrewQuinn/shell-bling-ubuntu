#!/bin/sh
# Final interactive fzf pickers. Skipped entirely when
# SHELL_BLING_NONINTERACTIVE=1 (Docker tests, CI, etc.).

run_pickers() {
  if [ "${SHELL_BLING_NONINTERACTIVE:-0}" = 1 ]; then
    log "Non-interactive mode; defaulting EDITOR to nvim, skipping chsh"
    fish_set_editor nvim
    return 0
  fi
  if ! has_cmd fzf; then
    warn "fzf not available; skipping pickers"
    return 0
  fi
  _pick_editor
  _pick_shell
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
    yes*) chsh -s "$(command -v fish)" || warn "chsh failed; you can run it manually" ;;
    *) log "Leaving login shell unchanged" ;;
  esac
}
