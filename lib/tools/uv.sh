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
  has_cmd uv && return 0
  case "$DISTRO" in
    macos)
      brew install uv
      return $?
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
    if fetch_to "$_url" "$_tmp/uv.tar.gz" \
      && tar -xzf "$_tmp/uv.tar.gz" -C "$_tmp"; then
      sudo_run install -m 0755 "$_tmp/uv-${_suffix}/uv"  /usr/local/bin/uv
      sudo_run install -m 0755 "$_tmp/uv-${_suffix}/uvx" /usr/local/bin/uvx
      rm -rf "$_tmp"
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
  return $_rc
}
