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
case "$DISTRO" in
  macos)
    # shellcheck source=lib/platform_macos.sh
    . "$_lib_dir/platform_macos.sh"
    platform_macos_preflight
    ;;
  fedora)
    # shellcheck source=lib/platform_fedora.sh
    . "$_lib_dir/platform_fedora.sh"
    ;;
esac
if [ "$IS_WSL" = 1 ]; then
  # shellcheck source=lib/platform_wsl.sh
  . "$_lib_dir/platform_wsl.sh"
  platform_wsl_preflight
fi

# ---------- universal packages (apt/dnf/brew) ---------------------------------
log "Installing universal packages"
case "$DISTRO" in
  ubuntu | debian)
    pkg_install \
      curl git ca-certificates gnupg \
      fish \
      ripgrep jq tmux tree htop \
      bat fd-find xclip lnav gron \
      micro csvkit \
      gcc g++ make nodejs
    # vim-gtk3 only available where a GUI stack is present; fall back to vim.
    pkg_install vim-gtk3 2> /dev/null || pkg_install vim
    # kitty is GUI; not always in minimal containers.
    pkg_install kitty 2> /dev/null || warn "kitty unavailable; skipping"
    # Ubuntu-only: PPA helper.
    if [ "$DISTRO" = ubuntu ]; then
      pkg_install software-properties-common 2> /dev/null || true
    fi
    ;;
  fedora)
    # shellcheck disable=SC2046  # word splitting wanted
    pkg_install $(platform_fedora_universal_pkgs) ||
      warn "some Fedora packages may not be available; per-tool installers will fill in"
    ;;
  macos)
    # shellcheck disable=SC2046
    pkg_install $(platform_macos_universal_pkgs)
    ;;
esac

# ---------- per-tool installers (snap-free, arch-aware) -----------------------
for _t in neovim lazygit helix lsd eza starship zoxide fzf uv gopass tldr gh cheat delta; do
  # shellcheck source=/dev/null
  . "$_lib_dir/tools/$_t.sh"
  "install_$_t" || warn "install_$_t failed (continuing)"
done

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
[ "${SHELL_BLING_SKIP_LAZYVIM:-0}" = 1 ] || setup_lazyvim
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

printf '\033[1;32m==> Shell Bling installed.\033[0m\n'
printf 'Restart your terminal to pick up everything. Welcome.\n'
