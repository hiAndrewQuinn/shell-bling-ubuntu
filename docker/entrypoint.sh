#!/bin/sh
# Runs inside test containers. Either runs install.sh non-interactively
# and exits (CI mode) or drops to an interactive shell (dev mode).

set -eu
cd /home/dev/shell-bling-ubuntu

export SHELL_BLING_NONINTERACTIVE=1

if [ "${SHELL_BLING_DEV:-0}" = 1 ]; then
  unset SHELL_BLING_NONINTERACTIVE
  sh install.sh || true
  printf '\n\033[1;33m==> install.sh finished. Dropping to bash.\033[0m\n'
  exec bash -l
fi

sh install.sh
# Smoke test: required commands on PATH. ~/.cargo/bin / /usr/local/go/bin
# aren't in this script's PATH yet (no shell restart) so source them.
PATH="$HOME/.cargo/bin:/usr/local/go/bin:$HOME/.local/bin:$PATH"
export PATH
MISSING=""
for cmd in fish fzf nvim git curl rg fd bat zoxide starship \
  lazygit gh uv eza gopass pass qsv cargo rustc rustup go; do
  command -v "$cmd" > /dev/null 2>&1 || MISSING="$MISSING $cmd"
done
if [ -n "$MISSING" ]; then
  echo "MISSING:$MISSING"
  exit 1
fi
# nvim must be at least 0.11 for LazyVim.
NVIM_VER=$(nvim --version | awk 'NR==1 {gsub(/^v/,"",$2); print $2}')
case "$NVIM_VER" in
  0.[0-9].* | 0.10.*)
    echo "nvim version too old: $NVIM_VER (need >=0.11)"
    exit 1
    ;;
esac
echo "==> smoke test PASS (nvim $NVIM_VER)"
