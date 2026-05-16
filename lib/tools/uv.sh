#!/bin/sh
# Install uv (astral) — Python package manager.
#
# Strategy: prefer the GitHub release tarball (same pattern as every other
# tool here — single trusted host, github.com, which we already need for
# the repo itself). Fall back to the astral.sh installer if the tarball
# path fails for any reason. This avoids depending on astral.sh being
# reachable from every network we install on (observed: some PVE VM
# networks reliably can't reach astral.sh while github.com works fine).

install_uv() {
  if has_cmd uv; then
    _uv_install_latest_python
    return 0
  fi
  case "$DISTRO" in
    macos)
      brew install uv || return $?
      _uv_install_latest_python
      return 0
      ;;
  esac

  case "$ARCH" in
    amd64) _suffix=x86_64-unknown-linux-gnu ;;
    arm64) _suffix=aarch64-unknown-linux-gnu ;;
    *)
      err "no uv build for arch $ARCH"
      return 1
      ;;
  esac

  _ver=$(github_latest_tag astral-sh/uv)
  if [ -n "$_ver" ]; then
    _url="https://github.com/astral-sh/uv/releases/download/${_ver}/uv-${_suffix}.tar.gz"
    _tmp=$(mktemp -d)
    log "Installing uv $_ver ($_suffix)"
    if fetch_to "$_url" "$_tmp/uv.tar.gz" &&
      tar -xzf "$_tmp/uv.tar.gz" -C "$_tmp"; then
      sudo_run install -m 0755 "$_tmp/uv-${_suffix}/uv" /usr/local/bin/uv
      sudo_run install -m 0755 "$_tmp/uv-${_suffix}/uvx" /usr/local/bin/uvx
      rm -rf "$_tmp"
      _uv_install_latest_python
      return 0
    fi
    rm -rf "$_tmp"
    warn "uv GitHub release install failed; falling back to astral.sh installer"
  fi

  log "Installing uv via astral.sh installer (fallback)"
  __sb_uv_tmp=$(mktemp -d)
  curl -LsSf https://astral.sh/uv/install.sh -o "$__sb_uv_tmp/uv-install.sh" || {
    rm -rf "$__sb_uv_tmp"
    err "could not download uv installer from astral.sh"
    return 1
  }
  UV_UNMANAGED_INSTALL=/usr/local/bin sudo_run sh "$__sb_uv_tmp/uv-install.sh" > /dev/null
  _rc=$?
  rm -rf "$__sb_uv_tmp"
  [ "$_rc" -eq 0 ] && _uv_install_latest_python
  return "$_rc"
}

# Pre-install the latest stable CPython so `uv run`, `uv venv`, and
# `python` (after PATH wiring) Just Work for the invoking user without a
# separate trip. Best-effort: don't fail the installer if it can't reach
# the index. Skipped under SHELL_BLING_SKIP_TOOLCHAINS=1.
_uv_install_latest_python() {
  has_cmd uv || return 0
  if [ "${SHELL_BLING_SKIP_TOOLCHAINS:-0}" = 1 ]; then
    log "SHELL_BLING_SKIP_TOOLCHAINS=1 — skipping uv python install"
    return 0
  fi
  # Skip if at least one managed CPython is already present.
  if uv python list --only-installed 2> /dev/null | grep -qi cpython; then
    return 0
  fi
  log "Installing latest stable CPython via uv"
  uv python install > /dev/null 2>&1 || warn "uv python install failed (run it manually later)"
}
