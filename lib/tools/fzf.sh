#!/bin/sh
# Post-install hook for fzf (registered in lib/registry.sh).
# The engine has already installed the fzf binary; fzf's shell-integration
# scripts (key-bindings.fish, completion.fish) live in the source repo, not
# the binary release, so we fetch them from raw.githubusercontent.com pinned
# to the same tag. Installed to /usr/share/fzf/ where fish_setup wires them.

fzf_postinstall() {
  _dest=/usr/share/fzf
  sudo_run mkdir -p "$_dest"
  for _f in key-bindings.fish completion.fish key-bindings.bash completion.bash; do
    _url="https://raw.githubusercontent.com/junegunn/fzf/v${FZF_VERSION}/shell/${_f}"
    _tmp=$(mktemp)
    if fetch_to "$_url" "$_tmp" 2> /dev/null; then
      sudo_run install -m 0644 "$_tmp" "$_dest/$_f"
    else
      warn "fzf: could not fetch shell script $_f (non-fatal)"
    fi
    rm -f "$_tmp"
  done
}
