#!/bin/sh
# Install qsv — Rust-based CSV/data Swiss army knife. Replaces csvkit.
# Source: dathere/qsv GitHub releases; assets are zipped per-triple.

install_qsv() {
  has_cmd qsv && return 0
  case "$DISTRO" in
    macos)
      brew install qsv
      return $?
      ;;
  esac

  case "$ARCH" in
    amd64) _suffix=x86_64-unknown-linux-gnu ;;
    arm64) _suffix=aarch64-unknown-linux-gnu ;;
    *)
      warn "no qsv build for arch $ARCH; skipping"
      return 0
      ;;
  esac

  _ver=$(github_latest_tag dathere/qsv)
  [ -n "$_ver" ] || {
    warn "could not resolve qsv version; skipping"
    return 0
  }

  if ! has_cmd unzip; then
    warn "unzip not present; cannot install qsv"
    return 0
  fi

  _url="https://github.com/dathere/qsv/releases/download/${_ver}/qsv-${_ver}-${_suffix}.zip"
  _tmp=$(mktemp -d)
  log "Installing qsv $_ver ($_suffix)"
  if ! fetch_to "$_url" "$_tmp/qsv.zip"; then
    rm -rf "$_tmp"
    return 1
  fi
  unzip -q -o "$_tmp/qsv.zip" -d "$_tmp"
  sudo_run install -m 0755 "$_tmp/qsv" /usr/local/bin/qsv
  # qsv ships qsvlite + qsvdp alongside; install them if present so users can
  # opt into the smaller binaries.
  [ -f "$_tmp/qsvlite" ] && sudo_run install -m 0755 "$_tmp/qsvlite" /usr/local/bin/qsvlite
  [ -f "$_tmp/qsvdp" ] && sudo_run install -m 0755 "$_tmp/qsvdp" /usr/local/bin/qsvdp
  rm -rf "$_tmp"
}
