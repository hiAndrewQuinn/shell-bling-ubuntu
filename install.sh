#!/bin/sh
# shell-bling — single-script installer.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/hiAndrewQuinn/shell-bling-ubuntu/main/install.sh | sh
#
# Env vars:
#   SHELL_BLING_NONINTERACTIVE=1   skip fzf pickers, default editor=nvim, no chsh
#   SHELL_BLING_LIB_DIR=PATH       override where lib/ lives (default: auto)
#   SHELL_BLING_SKIP_LAZYVIM=1     skip the LazyVim starter clone

set -eu

# When curl-piped, $0 is "sh" and there are no library files locally. In that
# case we clone the repo to a temp dir and re-exec from there.
_self="${0:-}"
_lib_dir=${SHELL_BLING_LIB_DIR:-}
if [ -z "$_lib_dir" ]; then
  if [ -d "$(dirname "$_self" 2> /dev/null)/lib" ] 2> /dev/null; then
    _lib_dir="$(cd "$(dirname "$_self")" && pwd)/lib"
  else
    _tmp_clone=$(mktemp -d)
    printf '\033[36m==>\033[0m Cloning shell-bling-ubuntu into %s\n' "$_tmp_clone"
    git clone --depth 1 https://github.com/hiAndrewQuinn/shell-bling-ubuntu \
      "$_tmp_clone" > /dev/null 2>&1 || {
      printf '\033[31m==> ERROR:\033[0m git clone failed; do you have git installed?\n' >&2
      exit 1
    }
    _lib_dir="$_tmp_clone/lib"
    # Re-exec to pick up the bundled scripts.
    exec sh "$_tmp_clone/install.sh" "$@"
  fi
fi

# shellcheck source=lib/detect.sh
. "$_lib_dir/detect.sh"
# shellcheck source=lib/pkg.sh
. "$_lib_dir/pkg.sh"
# shellcheck source=lib/registry.sh
. "$_lib_dir/registry.sh"
# shellcheck source=lib/registry_install.sh
. "$_lib_dir/registry_install.sh"
# shellcheck source=lib/registry_sigverify.sh
. "$_lib_dir/registry_sigverify.sh"
# shellcheck source=lib/registry_verify.sh
. "$_lib_dir/registry_verify.sh"

log "Detected platform:"
detect_print_summary

case "$SUPPORT_TIER" in
  tier1)
    log "Tier-1 supported platform."
    ;;
  experimental)
    warn "Experimental platform. Best-effort install — please file issues."
    ;;
  unsupported)
    err "Unsupported platform: $DISTRO $CODENAME ($OS_FAMILY/$ARCH)"
    err "Supported: Ubuntu 22.04/24.04/26.04, Debian 12/13. Experimental: Fedora, macOS, WSL2."
    exit 1
    ;;
esac

# ---------- CPU feature probe (warn-only) -------------------------------------
# Modern Rust prebuilt binaries (qsv, ripgrep, fd, bat, eza, zoxide, starship)
# can assume SSE4.2/AVX2 from rustc's default codegen for x86_64-unknown-linux-
# gnu. KVM with the default cpu=kvm64 model masks these flags and the binaries
# SIGILL at first invocation. Warn but don't block — the install still works
# for everything except those specific Rust binaries, and arm64/macOS users
# legitimately don't have these flags.
if [ "$ARCH" = amd64 ] && [ -r /proc/cpuinfo ]; then
  if ! grep -m1 -q '^flags.*\bavx2\b' /proc/cpuinfo ||
    ! grep -m1 -q '^flags.*\bsse4_2\b' /proc/cpuinfo; then
    warn "CPU does not expose AVX2/SSE4.2. Some prebuilt Rust binaries"
    warn "  (qsv, rg, fd, bat, eza, zoxide, starship) may SIGILL when run."
    warn "  Common cause: a KVM VM with cpu=kvm64. If you control the host,"
    warn "  switch to cpu=host or cpu=x86-64-v3 and reboot the VM."
    warn "  This install will continue."
  fi
fi

# ---------- Disk space preflight ----------------------------------------------
# Peak install footprint is ~1 GB: apt packages + GitHub release downloads
# for the registry tools + LazyVim bootstrap. Override with
# SHELL_BLING_BYPASS_SIZE=1.
if [ "${SHELL_BLING_BYPASS_SIZE:-0}" != 1 ]; then
  # POSIX `df -P -k` gives portable output; field 4 is available KB.
  _avail_kb=$(df -P -k "$HOME" 2> /dev/null | awk 'NR==2 {print $4}')
  if [ -n "$_avail_kb" ]; then
    _avail_gb=$((_avail_kb / 1024 / 1024))
    if [ "$_avail_gb" -lt 1 ]; then
      err "Not enough disk space on \$HOME: have ${_avail_gb} GB, need ~1 GB."
      err "Free some disk, or override with SHELL_BLING_BYPASS_SIZE=1."
      exit 1
    fi
  fi
fi

# ---------- sudo preflight + keepalive ----------------------------------------
_sudo_keepalive_pid=""
_start_sudo_keepalive() {
  [ "$OS_FAMILY" = darwin ] && return 0
  [ "$(id -u)" = 0 ] && return 0
  has_cmd sudo || {
    warn "sudo not found; assuming root"
    return 0
  }
  # Passwordless sudo (CI, NOPASSWD)? No keepalive needed.
  if sudo -n true 2> /dev/null; then
    log "Passwordless sudo detected; no password needed"
    return 0
  fi
  if [ "${SHELL_BLING_NONINTERACTIVE:-0}" = 1 ]; then
    err "Non-interactive mode requested but sudo needs a password."
    err "Configure passwordless sudo or run install.sh interactively."
    exit 1
  fi
  log "Asking for your password once up front (sudo)"
  sudo -v
  # Keep the timestamp fresh until install finishes.
  (while true; do
    sudo -n true
    sleep 50
  done) 2> /dev/null &
  _sudo_keepalive_pid=$!
}
_stop_sudo_keepalive() {
  [ -n "$_sudo_keepalive_pid" ] && kill "$_sudo_keepalive_pid" 2> /dev/null || true
}
trap _stop_sudo_keepalive EXIT INT TERM

_start_sudo_keepalive

# ---------- platform-specific preflight ---------------------------------------
# Every supported distro has its own lib/platform_<distro>.sh, which exposes
# platform_<distro>_universal_pkgs() and (optionally) platform_<distro>_preflight().
# shellcheck source=/dev/null
. "$_lib_dir/platform_$DISTRO.sh"
if command -v "platform_${DISTRO}_preflight" > /dev/null 2>&1; then
  "platform_${DISTRO}_preflight"
fi
if [ "$IS_WSL" = 1 ]; then
  # shellcheck source=lib/platform_wsl.sh
  . "$_lib_dir/platform_wsl.sh"
  platform_wsl_preflight
fi

# ---------- universal packages (apt/dnf/pacman/apk/zypper/brew) ---------------
# Every supported distro exposes its package list via the same function
# pattern: platform_<distro>_universal_pkgs. install.sh dispatches to it
# uniformly — Ubuntu and Debian no longer have a hardcoded inline list.
log "Installing universal packages"
# shellcheck disable=SC2046  # word splitting is the goal
pkg_install $("platform_${DISTRO}_universal_pkgs") ||
  warn "some $DISTRO packages may not be available; per-tool / registry installers will fill in"

# ---------- per-tool installers ----------------------------------------------
# Source every lib/tools/*.sh so registry post-install hooks and the remaining
# legacy install_<tool> functions are all defined before we run the engine.
# Sourcing is side-effect-free (each file just defines functions).
for _f in "$_lib_dir"/tools/*.sh; do
  # shellcheck source=/dev/null
  . "$_f"
done

# ---------- registry-driven static-binary installs ----------------------------
# Pull static binaries straight from upstream (vendor releases) for every tool
# whose vendor publishes one. Parallel fetch + sequential install + smoke
# test. All version pinning lives in lib/registry.sh; per-(arch,libc) URL
# gaps fall back to pkg_install automatically.
_reg_workdir=$(mktemp -d -t shell-bling-registry-XXXXXX)
trap 'rm -rf "$_reg_workdir"; _stop_sudo_keepalive' EXIT INT TERM
registry_fetch_all "$REGISTRY_TOOLS" "$_reg_workdir"
registry_install_all "$REGISTRY_TOOLS" "$_reg_workdir"

# All tools now flow through the registry — no legacy per-tool loop.

# ---------- user-level setup --------------------------------------------------
# shellcheck source=lib/kitty_setup.sh
. "$_lib_dir/kitty_setup.sh"
# shellcheck source=lib/git_setup.sh
. "$_lib_dir/git_setup.sh"
# shellcheck source=lib/lazyvim_setup.sh
. "$_lib_dir/lazyvim_setup.sh"
# shellcheck source=lib/fish_setup.sh
. "$_lib_dir/fish_setup.sh"

setup_kitty
setup_git
# LazyVim needs Neovim >= 0.11. If nvim is older (e.g. Alpine's apk-shipped
# 0.10.x), skip the starter clone so we don't leave a broken config behind.
_skip_lazyvim=${SHELL_BLING_SKIP_LAZYVIM:-0}
if [ "$_skip_lazyvim" != 1 ] && has_cmd nvim; then
  _nvim_ver=$(nvim --version 2> /dev/null | awk 'NR==1 {gsub(/^v/,"",$2); print $2}')
  case "$_nvim_ver" in
    0.[0-9].* | 0.10.*)
      warn "Neovim $_nvim_ver < 0.11 — skipping LazyVim starter clone"
      _skip_lazyvim=1
      ;;
  esac
fi
[ "$_skip_lazyvim" = 1 ] || setup_lazyvim
setup_fish

# show_random_whatis function — keep in sync with what's installed.
if has_cmd fish; then
  mkdir -p "$HOME/.config/fish/functions"
  if [ -f "$_lib_dir/../show_random_whatis.fish" ]; then
    cp "$_lib_dir/../show_random_whatis.fish" "$HOME/.config/fish/functions/show_random_whatis.fish"
  fi
fi

# ---------- pickers (interactive only) ----------------------------------------
_stop_sudo_keepalive
# shellcheck source=lib/pickers.sh
. "$_lib_dir/pickers.sh"
run_pickers

# Post-install sanity check: every registry tool's --version must report
# the version we pinned. Default warn-only — operator sees a table at the
# end and decides whether drift is acceptable. SHELL_BLING_STRICT_VERSIONS=1
# (set by docker/entrypoint.sh + the Jenkins matrix) turns drift into a
# hard install failure.
registry_verify_all "$REGISTRY_TOOLS" || exit $?

printf '\033[1;32m==> Shell Bling installed.\033[0m\n'
printf 'Restart your terminal to pick up everything. Welcome.\n'
