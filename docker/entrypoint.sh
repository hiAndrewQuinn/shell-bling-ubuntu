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
# Smoke test: required commands on PATH.
for cmd in fish fzf nvim git curl rg fd bat zoxide starship; do
  command -v "$cmd" > /dev/null 2>&1 || {
    echo "MISSING: $cmd"
    exit 1
  }
done
echo "==> smoke test PASS"
