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

  # qsv's prebuilt -gnu binaries are built against a recent glibc (~2.38+).
  # Debian 12 / Ubuntu 22.04 ship 2.36 / 2.35 and the binary won't dynamically
  # link. Fall back to the -musl static build there.
  _libc_variant=gnu
  _glibc_ver=""
  if [ -n "$(command -v ldd 2> /dev/null)" ]; then
    _ldd_out=$(ldd --version 2>&1 | head -2)
    # Alpine / musl-based: ldd --version prints "musl libc (x86_64)\nVersion ..."
    if printf '%s\n' "$_ldd_out" | grep -qi musl; then
      _libc_variant=musl
    else
      _glibc_ver=$(printf '%s\n' "$_ldd_out" | awk 'NR==1 {print $NF}')
      case "$_glibc_ver" in
        2.[0-9] | 2.[0-9].* | 2.[12][0-9] | 2.[12][0-9].* | 2.3[0-7] | 2.3[0-7].*)
          _libc_variant=musl
          ;;
      esac
    fi
  fi
  case "$ARCH" in
    amd64) _suffix=x86_64-unknown-linux-${_libc_variant} ;;
    arm64)
      # qsv only ships aarch64-unknown-linux-gnu (no musl variant). Old-glibc
      # arm64 hosts are out of luck — warn and skip.
      if [ "$_libc_variant" = musl ]; then
        warn "qsv has no aarch64 musl build; skipping (glibc too old: $_glibc_ver)"
        return 0
      fi
      _suffix=aarch64-unknown-linux-gnu
      ;;
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
