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
    # pkg.sh isn't sourced yet, so honor NO_COLOR inline for these two lines.
    if [ -n "${NO_COLOR-}" ]; then
      _bs_cyan=''
      _bs_red=''
      _bs_rst=''
    else
      _bs_cyan=$(printf '\033[36m')
      _bs_red=$(printf '\033[31m')
      _bs_rst=$(printf '\033[0m')
    fi
    # _bs_ensure_git — runs before the clone. If git isn't installed,
    # parse /etc/os-release inline, pick the right package manager,
    # detect privilege escalation (root | sudo | doas) using only POSIX
    # builtins (lib/* isn't sourced yet), install git, return. This
    # turns the previously fatal "git not installed" wget|sh failure
    # into a one-password-prompt detour on minimal systems like fresh
    # Debian 13 (no curl, no git, just wget).
    _bs_ensure_git() {
      command -v git > /dev/null 2>&1 && return 0

      _bs_id=""
      if [ -r /etc/os-release ]; then
        # Subshell so . doesn't leak ID/VERSION_ID/etc. into install.sh's
        # scope before lib/detect.sh has a chance to do its richer parse.
        _bs_id=$(. /etc/os-release 2> /dev/null && printf '%s' "${ID:-}")
      fi

      _bs_priv=""
      if [ "$(id -u 2> /dev/null || echo 0)" != 0 ]; then
        if command -v sudo > /dev/null 2>&1; then
          _bs_priv=sudo
        elif command -v doas > /dev/null 2>&1; then
          _bs_priv=doas
        else
          printf '%s==> ERROR:%s git is not installed, and neither sudo nor doas is\n' "$_bs_red" "$_bs_rst" >&2
          printf '       available to install it for you. As root, run:\n' >&2
          printf '         apt update && apt install -y git    # Debian/Ubuntu\n' >&2
          printf '         dnf install -y git                  # Fedora/RHEL\n' >&2
          printf '         apk add git                         # Alpine\n' >&2
          printf '       Then re-run this install one-liner.\n' >&2
          exit 1
        fi
      fi

      # Probe escalation usability *before* attempting the install.
      # Without this, a non-sudoer hits sudo's password prompt, types it,
      # and then sudo says "user is not in the sudoers file." — having
      # wasted an auth attempt to learn what we could detect now.
      # Skip the probe when running as root (_bs_priv is empty).
      _bs_die_no_perms() {
        _bs_u=$(id -un 2> /dev/null || echo user)
        printf '%s==> ERROR:%s %s is installed but %s is not permitted to use it.\n' \
          "$_bs_red" "$_bs_rst" "$_bs_priv" "$_bs_u" >&2
        printf '       Typing a password will not help — your user is missing from\n' >&2
        printf "       the sudoers/wheel group (or doas.conf has no 'permit' rule).\n\n" >&2
        printf '       Fix as root (su -), log out + back in, then re-run:\n\n' >&2
        if [ "$_bs_priv" = sudo ]; then
          case "$_bs_id" in
            debian | ubuntu | kali)
              printf "         su -c 'usermod -aG sudo %s'\n" "$_bs_u" >&2
              ;;
            fedora | rocky | almalinux | centos | amzn | rhel | arch | manjaro | manjaro-arm | void | opensuse* | sles | sled)
              printf "         su -c 'usermod -aG wheel %s'\n" "$_bs_u" >&2
              ;;
            alpine)
              printf "         su -c 'addgroup %s wheel'\n" "$_bs_u" >&2
              ;;
            *)
              printf "         su -c 'usermod -aG sudo %s'   # Debian/Ubuntu/Kali\n" "$_bs_u" >&2
              printf "         su -c 'usermod -aG wheel %s'  # Fedora/RHEL/Arch/Void/openSUSE\n" "$_bs_u" >&2
              printf "         su -c 'addgroup %s wheel'     # Alpine\n" "$_bs_u" >&2
              ;;
          esac
        else
          case "$_bs_id" in
            alpine)
              printf "         su -c 'echo \"permit persist %s\" >> /etc/doas.d/shell-bling.conf'\n" "$_bs_u" >&2
              ;;
            *)
              printf "         su -c 'echo \"permit persist %s\" >> /etc/doas.conf'\n" "$_bs_u" >&2
              ;;
          esac
        fi
        printf '\n       Or, faster, skip group setup entirely by running as root:\n\n' >&2
        printf '         su -\n' >&2
        printf '         <re-run the install one-liner>\n\n' >&2
        unset _bs_u
        exit 1
      }
      case "$_bs_priv" in
        sudo)
          # Group-membership probe. The sudo daemon gates on the
          # `%sudo` (Debian/Ubuntu/Kali) or `%wheel` (everyone else)
          # group. Parsing `sudo -n -v` stderr instead is unreliable:
          # on Debian 13 it prints "a password is required" for
          # non-sudoers (auth check runs before sudoers check), which
          # an earlier version of this probe misread as "in sudoers".
          # Membership in *any* of sudo/wheel/admin is sufficient
          # signal that the user can probably sudo. (`admin` covers
          # old Ubuntu and macOS.) Edge case: per-user entries in
          # /etc/sudoers.d/ with no group membership get false-positive
          # bailed; power users can `sudo sh -c '...'` directly.
          case " $(id -nG 2> /dev/null) " in
            *" sudo "* | *" wheel "* | *" admin "*) ;;
            *) _bs_die_no_perms ;;
          esac
          ;;
        doas)
          # doas doesn't use group abstraction — permits are in
          # /etc/doas.conf. Stderr parsing is the available signal.
          _bs_probe=$(doas -n true 2>&1) || true
          case "$_bs_probe" in
            "" | *"Authentication required"*) ;; # persist active or needs pw
            *"not permitted"* | *"not allowed"*)
              _bs_die_no_perms
              ;;
          esac
          unset _bs_probe
          ;;
      esac

      printf '%s==>%s git not found; installing via the system package manager\n' \
        "$_bs_cyan" "$_bs_rst"
      case "$_bs_id" in
        debian | ubuntu | kali)
          $_bs_priv env DEBIAN_FRONTEND=noninteractive apt-get update -y > /dev/null &&
            $_bs_priv env DEBIAN_FRONTEND=noninteractive apt-get install -y git
          ;;
        fedora | rocky | almalinux | centos | amzn | rhel)
          $_bs_priv dnf install -y git 2> /dev/null ||
            $_bs_priv yum install -y git
          ;;
        arch | manjaro | manjaro-arm)
          $_bs_priv pacman -Sy --noconfirm git
          ;;
        alpine)
          $_bs_priv apk add --no-cache git
          ;;
        void)
          $_bs_priv xbps-install -Sy git
          ;;
        opensuse* | sles | sled)
          $_bs_priv zypper install -y git
          ;;
        "")
          printf '%s==> ERROR:%s git missing and /etc/os-release could not be read.\n' \
            "$_bs_red" "$_bs_rst" >&2
          printf '       Install git via your distro and re-run.\n' >&2
          exit 1
          ;;
        *)
          printf '%s==> ERROR:%s git missing and unrecognized distro (ID=%s).\n' \
            "$_bs_red" "$_bs_rst" "$_bs_id" >&2
          printf '       Install git via your distro and re-run.\n' >&2
          exit 1
          ;;
      esac

      command -v git > /dev/null 2>&1 || {
        printf '%s==> ERROR:%s package install completed but git is still not on PATH.\n' \
          "$_bs_red" "$_bs_rst" >&2
        exit 1
      }
      unset _bs_id _bs_priv
    }
    _bs_ensure_git

    printf '%s==>%s Cloning shell-bling-ubuntu into %s\n' "$_bs_cyan" "$_bs_rst" "$_tmp_clone"
    git clone --depth 1 https://github.com/hiAndrewQuinn/shell-bling-ubuntu \
      "$_tmp_clone" > /dev/null 2>&1 || {
      printf '%s==> ERROR:%s git clone failed (network? repo URL?).\n' "$_bs_red" "$_bs_rst" >&2
      exit 1
    }
    unset _bs_cyan _bs_red _bs_rst
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
log "System resources (phase=start):"
detect_print_resources start

case "$SUPPORT_TIER" in
  tier1)
    log "Tier-1 supported platform."
    ;;
  experimental)
    warn "Experimental platform. Best-effort install — please file issues."
    ;;
  unsupported)
    err "Unsupported platform: $DISTRO $CODENAME ($OS_FAMILY/$ARCH)"
    err "Supported: Ubuntu 20.04/22.04/24.04/26.04, Debian 11/12/13. Experimental: Fedora, macOS, WSL2, Arch, Alpine, openSUSE."
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

# ---------- privilege-escalation preflight + sudo keepalive -------------------
# Populates PRIV_ESC (lib/detect.sh) once at startup. If the user is non-root
# and has no privilege-escalation tool, we bail here with an actionable,
# distro-specific message — *before* any apt/dnf/etc. activity — instead of
# letting the install crash with "sudo: command not found" 30 seconds later.
_sudo_keepalive_pid=""

# Print recovery guidance and exit 1. $DISTRO is set by lib/detect.sh.
_priv_esc_help_and_exit() {
  _u=$(id -un 2> /dev/null || echo user)
  err "Need root to install packages, but no 'sudo' or 'doas' was found."
  cat >&2 << EOF

  shell-bling installs system packages, which requires root.
  You're running as '${_u}' and neither 'sudo' nor 'doas' is on PATH.

  Pick one of:

  1) Re-run as root:
       su -
       <re-run the install one-liner>

  2) Install sudo, then re-run as your user:
EOF
  case "$DISTRO" in
    debian | ubuntu)
      printf "       su -c 'apt update && apt install -y sudo && usermod -aG sudo %s'\n" "$_u" >&2
      ;;
    fedora | rhel)
      printf "       su -c 'dnf install -y sudo && usermod -aG wheel %s'\n" "$_u" >&2
      ;;
    arch)
      printf "       su -c 'pacman -S --noconfirm sudo && usermod -aG wheel %s'\n" "$_u" >&2
      ;;
    alpine)
      printf "       su -c 'apk add sudo && addgroup %s wheel'\n" "$_u" >&2
      ;;
    void)
      printf "       su -c 'xbps-install -y sudo && usermod -aG wheel %s'\n" "$_u" >&2
      ;;
    opensuse)
      printf "       su -c 'zypper install -y sudo && usermod -aG wheel %s'\n" "$_u" >&2
      ;;
    *)
      printf "       (see your distro's docs to install 'sudo')\n" >&2
      ;;
  esac
  cat >&2 << EOF

  3) Or install doas (lighter-weight; common on Alpine/Void):
EOF
  case "$DISTRO" in
    alpine)
      printf "       su -c 'apk add doas && echo \"permit persist %s\" >> /etc/doas.d/shell-bling.conf'\n" "$_u" >&2
      ;;
    void)
      printf "       su -c 'xbps-install -y opendoas && echo \"permit persist %s\" >> /etc/doas.conf'\n" "$_u" >&2
      ;;
    arch)
      printf "       su -c 'pacman -S --noconfirm opendoas && echo \"permit persist %s\" >> /etc/doas.conf'\n" "$_u" >&2
      ;;
    *)
      printf "       (doas/opendoas package varies by distro; see its docs)\n" >&2
      ;;
  esac
  cat >&2 << EOF

  After option 2 or 3, log out and back in so group changes take effect.

EOF
  unset _u
  exit 1
}

# Print recovery guidance when the user *has* sudo or doas but isn't
# permitted to use it (not in the sudo/wheel group, or no `permit` rule
# in /etc/doas.conf). Distinct from _priv_esc_help_and_exit which fires
# when the binary itself is missing.
_priv_esc_no_perms_help_and_exit() {
  _u=$(id -un 2> /dev/null || echo user)
  err "'$PRIV_ESC' is installed, but '$_u' is not permitted to use it."
  cat >&2 << EOF

  shell-bling installs system packages, which requires root.
  '$PRIV_ESC' is on PATH but a non-prompting probe ('$PRIV_ESC -n -v' /
  '$PRIV_ESC -n true') failed with a permissions error — typing a password
  won't change that.

EOF
  if [ "$PRIV_ESC" = sudo ]; then
    cat >&2 << EOF
  As root (su -), add '$_u' to the right group:

EOF
    case "$DISTRO" in
      debian | ubuntu)
        printf "       su -c 'usermod -aG sudo %s'\n" "$_u" >&2
        ;;
      fedora | rhel | arch | opensuse | void)
        printf "       su -c 'usermod -aG wheel %s'\n" "$_u" >&2
        ;;
      alpine)
        printf "       su -c 'addgroup %s wheel'\n" "$_u" >&2
        ;;
      *)
        printf "       su -c 'usermod -aG sudo %s'   # Debian/Ubuntu/Kali\n" "$_u" >&2
        printf "       su -c 'usermod -aG wheel %s'  # Fedora/RHEL/Arch/Void/openSUSE\n" "$_u" >&2
        printf "       su -c 'addgroup %s wheel'     # Alpine\n" "$_u" >&2
        ;;
    esac
  else
    cat >&2 << EOF
  As root (su -), add a permit rule for '$_u':

EOF
    case "$DISTRO" in
      alpine)
        printf "       su -c 'echo \"permit persist %s\" >> /etc/doas.d/shell-bling.conf'\n" "$_u" >&2
        ;;
      *)
        printf "       su -c 'echo \"permit persist %s\" >> /etc/doas.conf'\n" "$_u" >&2
        ;;
    esac
  fi
  cat >&2 << EOF

  Then **log out and back in** so the new group membership takes effect,
  and re-run the install one-liner.

EOF
  unset _u
  exit 1
}

_start_sudo_keepalive() {
  # Always populate PRIV_ESC; it's the input to sudo_run.
  # detect_priv_esc returns:
  #   0 = usable (root, cached/NOPASSWD, or sudo will prompt)
  #   1 = no escalation binary at all
  #   2 = binary present but user has no permissions
  # `||` keeps set -e happy on non-zero; `_rc=$?` captures the code
  # *inside the failure branch*, where it's still meaningful.
  detect_priv_esc || _rc=$?
  case "${_rc:-0}" in
    0) ;;
    1) _priv_esc_help_and_exit ;;
    2) _priv_esc_no_perms_help_and_exit ;;
    *) _priv_esc_help_and_exit ;;
  esac
  unset _rc 2> /dev/null || true

  # Already root → nothing more to do; PRIV_ESC stays empty.
  [ -z "$PRIV_ESC" ] && return 0

  # macOS: one sudo prompt is fine, no need for a background keepalive
  # (brew handles most of the install on its own).
  [ "$OS_FAMILY" = darwin ] && return 0

  # doas: persistence is configured per-system in /etc/doas.conf
  # ('permit persist'). There's no portable analog to `sudo -n true`
  # for keeping the timestamp warm, so just rely on doas's own behavior.
  [ "$PRIV_ESC" = doas ] && return 0

  # From here on, PRIV_ESC=sudo. Passwordless sudo (CI, NOPASSWD)?
  # No keepalive needed.
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
# Reclaim ~270 MB of apt cache (and equivalents) before snapshotting —
# the resources block then reflects steady-state, not transient bloat.
pkg_cleanup
log "System resources (phase=post-apt):"
detect_print_resources post-apt

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
# Prefer /var/tmp (rootfs-backed on every distro we target) over /tmp,
# which is tmpfs on Debian 13 / modern Ubuntu and capped at ~half of RAM.
# qsv-gnu's 399 MB archive + 1.2 GB extracted tree blew the 988 MB tmpfs
# on the 2 GB test VMs in build #49; the rootfs at the same moment had
# 7+ GB free. Fall back to mktemp's default if /var/tmp is unwritable.
_reg_workdir=$(mktemp -d -p /var/tmp shell-bling-registry-XXXXXX 2> /dev/null ||
  mktemp -d -t shell-bling-registry-XXXXXX)
trap 'rm -rf "$_reg_workdir"; _stop_sudo_keepalive' EXIT INT TERM
registry_fetch_all "$REGISTRY_TOOLS" "$_reg_workdir"
log "System resources (phase=pre-install):"
detect_print_resources pre-install
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

# Known-unavailable surface: if the current platform has declared specific
# tools that genuinely cannot be installed (every fallback exhausted),
# call that out as a structured notice rather than letting it look like
# an unexpected verify failure. Strict-by-default posture is preserved;
# this only fires when we have *explicit* knowledge (a static list in
# lib/platform_<distro>.sh).
_known_fn="platform_${DISTRO}_known_unavailable"
if command -v "$_known_fn" > /dev/null 2>&1; then
  _known_out=$("$_known_fn" 2> /dev/null || true)
  if [ -n "$_known_out" ]; then
    echo
    printf '%s==> Known limitations on %s %s:%s\n' "$_SB_YEL" "$DISTRO" "$CODENAME" "$_SB_RST"
    printf '%s\n' "$_known_out" | sed 's/^/  /'
    echo
  fi
fi
unset _known_fn _known_out

log "System resources (phase=end):"
detect_print_resources end

printf '%s==> Shell Bling installed.%s\n' "$_SB_BLD_GRN" "$_SB_RST"
printf 'Restart your terminal to pick up everything. Welcome.\n'
