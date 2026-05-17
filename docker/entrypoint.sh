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
# Smoke test: every installed tool must actually execute, not just exist.
# `command -v` is not enough — a binary that SIGILLs (e.g. AVX2-using Rust
# binary on a cpu=kvm64 VM) passes `command -v` and crashes at run time.
# We invoke each tool's version subcommand (it's the lightest call that
# always exercises libc, dynamic loader, and the binary's own startup).
PATH="$HOME/.local/bin:$PATH"
export PATH

# Format: "cmd:version-subcommand". Most use --version; a few don't.
# No rustup/cargo/go/uv — those toolchains were dropped in R4.2 (shell-bling
# is a productive-shell installer, not a language-toolchain installer).
SMOKE_TESTS="
fish:--version
fzf:--version
nvim:--version
git:--version
curl:--version
rg:--version
fd:--version
bat:--version
zoxide:--version
starship:--version
lazygit:--version
gh:--version
eza:--version
gopass:--version
pass:--version
qsv:--version
tldr:--version
hx:--version
delta:--version
micro:-version
"

FAILED=""
# SHELL_BLING_SMOKE_OPTIONAL: space-separated tool names that are allowed to
# be missing on this distro (e.g. tldr on Alpine — no apk package). Tools in
# this list still fail the smoke test if they exist but crash on --version;
# they only get a pass when entirely absent.
_optional=${SHELL_BLING_SMOKE_OPTIONAL:-}
echo "==> smoke test: invoking --version on each tool"
for line in $SMOKE_TESTS; do
  cmd=${line%%:*}
  arg=${line#*:}
  if ! command -v "$cmd" > /dev/null 2>&1; then
    case " $_optional " in
      *" $cmd "*)
        echo "  $cmd (skipped — optional on this distro)"
        continue
        ;;
    esac
    FAILED="$FAILED\n  $cmd (not found on PATH)"
    continue
  fi
  # Capture rc without tripping `set -e`; POSIX `if ! foo` would clobber $? to 0/1.
  rc=0
  "$cmd" "$arg" > /dev/null 2>&1 || rc=$?
  if [ "$rc" -ne 0 ]; then
    # Distinguish SIGILL (132) and SIGSEGV (139) from a normal nonzero exit —
    # both are CPU-feature / link-time bugs we specifically want to catch.
    case $rc in
      132) FAILED="$FAILED\n  $cmd ($arg) → SIGILL (CPU feature missing? cpu=kvm64?)" ;;
      139) FAILED="$FAILED\n  $cmd ($arg) → SIGSEGV (linker issue?)" ;;
      *) FAILED="$FAILED\n  $cmd ($arg) → exit $rc" ;;
    esac
  fi
done

if [ -n "$FAILED" ]; then
  printf '==> smoke test FAIL:%b\n' "$FAILED"
  exit 1
fi

# Extra: nvim must be at least 0.11 for LazyVim. On distros where Neovim 0.11+
# isn't available without building from source (Alpine ships 0.10.x on edge),
# set SHELL_BLING_ALLOW_OLD_NVIM=1 — we still verify nvim runs, just don't
# block on version.
if ! command -v nvim > /dev/null 2>&1; then
  echo "==> smoke test PASS (nvim absent on this distro, all other tools execute)"
  exit 0
fi
NVIM_VER=$(nvim --version | awk 'NR==1 {gsub(/^v/,"",$2); print $2}')
case "$NVIM_VER" in
  0.[0-9].* | 0.10.*)
    if [ "${SHELL_BLING_ALLOW_OLD_NVIM:-0}" = 1 ]; then
      echo "==> smoke test PASS (nvim $NVIM_VER, all tools execute; LazyVim skipped — too old)"
      exit 0
    fi
    echo "==> smoke test FAIL: nvim version too old: $NVIM_VER (need >=0.11)"
    exit 1
    ;;
esac
echo "==> smoke test PASS (nvim $NVIM_VER, all tools execute)"
