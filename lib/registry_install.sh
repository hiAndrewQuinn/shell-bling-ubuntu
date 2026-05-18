#!/bin/sh
# lib/registry_install.sh — registry-driven static-binary install engine.
#
# Consumes pure-data tool entries from lib/registry.sh via indirect
# (eval-based) variable lookup. One code path covers every distro: the engine
# does fetch → verify → extract → install → smoke, with a pkg_install fallback
# when the upstream URL is unset for the current (arch, libc) or any step fails.
#
# Public entry points:
#   registry_fetch_all   "$REGISTRY_R41_TOOLS" "$WORKDIR"
#   registry_install_all "$REGISTRY_R41_TOOLS" "$WORKDIR"
#
# Requires: lib/detect.sh (ARCH, LIBC, DISTRO) and lib/pkg.sh (has_cmd, log,
# warn, err, sudo_run, pkg_install) already sourced.

# --- internal helpers ---------------------------------------------------------

# _reg_field TOOL FIELD  → echo the value of ${TOOL_UPPER}_${FIELD}
_reg_field() {
  __sb_T=$(printf '%s' "$1" | tr '[:lower:]-' '[:upper:]_')
  eval printf '%s' "\"\${${__sb_T}_$2:-}\""
}

# _reg_effective_libc TOOL  → echo "gnu" or "musl" after applying the
# gnu→musl swap when host glibc < ${TOOL}_GLIBC_MIN. Single source of
# truth for the libc-swap logic; called by _reg_url, _reg_hash, AND
# _reg_bin_in_archive so all three agree on which variant is in play.
# Before this helper existed, _reg_bin_in_archive used raw $LIBC while
# the URL/hash lookups had already swapped to musl — extracting a musl
# tarball using the gnu archive's internal path. Surfaced on Debian 11
# (delta's -musl tarball has a -musl-named subdir).
_reg_effective_libc() {
  __sb_T=$(printf '%s' "$1" | tr '[:lower:]-' '[:upper:]_')
  __sb_libc=$LIBC
  if [ "$__sb_libc" = gnu ] && [ -n "$GLIBC_VERSION" ]; then
    __sb_min=$(eval printf '%s' "\"\${${__sb_T}_GLIBC_MIN:-}\"")
    if [ -n "$__sb_min" ] && _reg_glibc_lt "$GLIBC_VERSION" "$__sb_min"; then
      __sb_libc=musl
    fi
  fi
  printf '%s' "$__sb_libc"
}

# _reg_url TOOL  → echo the URL for (ARCH, effective-LIBC), or empty.
# Falls back from gnu→musl when host glibc < ${TOOL}_GLIBC_MIN. Concretely:
# qsv's -gnu prebuilt needs glibc 2.38, but Debian 12 / Ubuntu 22.04 ship
# 2.36 / 2.35 — without this fallback those distros get a broken binary
# that exits 1 on --version.
_reg_url() {
  __sb_T=$(printf '%s' "$1" | tr '[:lower:]-' '[:upper:]_')
  __sb_libc=$(_reg_effective_libc "$1")
  eval printf '%s' "\"\${${__sb_T}_URL_${ARCH}_${__sb_libc}:-}\""
}

# _reg_glibc_lt A B  → exit 0 if version A < version B (POSIX dotted compare).
# Tolerates trailing junk like "2.36-ubuntu" by stripping non-digit-dot chars.
_reg_glibc_lt() {
  __sb_a=$(printf '%s' "$1" | tr -d -c '0-9.')
  __sb_b=$(printf '%s' "$2" | tr -d -c '0-9.')
  __sb_a1=${__sb_a%%.*}
  __sb_a2=${__sb_a#*.}
  __sb_a2=${__sb_a2%%.*}
  __sb_b1=${__sb_b%%.*}
  __sb_b2=${__sb_b#*.}
  __sb_b2=${__sb_b2%%.*}
  [ "$__sb_a1" -lt "$__sb_b1" ] && return 0
  [ "$__sb_a1" -gt "$__sb_b1" ] && return 1
  [ "$__sb_a2" -lt "$__sb_b2" ] && return 0
  return 1
}

# _reg_hash TOOL ALGO  → echo the pinned hash (sha256|sha512) for the
# current (ARCH, effective-LIBC), or empty if none was pinned. Uses the
# same arch/libc fallback as _reg_url so the hash matches the file we
# actually downloaded.
_reg_hash() {
  __sb_T=$(printf '%s' "$1" | tr '[:lower:]-' '[:upper:]_')
  __sb_algo=$(printf '%s' "$2" | tr '[:lower:]' '[:upper:]')
  __sb_libc=$(_reg_effective_libc "$1")
  eval printf '%s' "\"\${${__sb_T}_${__sb_algo}_${ARCH}_${__sb_libc}:-}\""
}

# _reg_bin_in_archive TOOL  → path relative to the extracted archive root.
# Tries _BIN_IN_ARCHIVE_${ARCH}_${effective-LIBC} → _BIN_IN_ARCHIVE_${ARCH}
# → _BIN_IN_ARCHIVE. Honors the same gnu→musl swap as _reg_url so we
# extract from the actual downloaded archive's directory layout.
_reg_bin_in_archive() {
  __sb_T=$(printf '%s' "$1" | tr '[:lower:]-' '[:upper:]_')
  __sb_libc=$(_reg_effective_libc "$1")
  __sb_v=$(eval printf '%s' "\"\${${__sb_T}_BIN_IN_ARCHIVE_${ARCH}_${__sb_libc}:-}\"")
  [ -n "$__sb_v" ] && {
    printf '%s\n' "$__sb_v"
    return
  }
  __sb_v=$(eval printf '%s' "\"\${${__sb_T}_BIN_IN_ARCHIVE_${ARCH}:-}\"")
  [ -n "$__sb_v" ] && {
    printf '%s\n' "$__sb_v"
    return
  }
  eval printf '%s\\n' "\"\${${__sb_T}_BIN_IN_ARCHIVE:-}\""
}

# --- fetch phase --------------------------------------------------------------

# registry_fetch_all TOOLS WORKDIR
#   Kicks one background curl per tool with a URL; waits for all to finish.
#   Writes per-tool status to $WORKDIR/<tool>.status (line 1: ok|fetch_failed|no_url;
#   line 2 on ok: absolute path to the downloaded archive).
registry_fetch_all() {
  __sb_tools=$1
  __sb_workdir=$2
  mkdir -p "$__sb_workdir"

  log "Registry: fetching upstream binaries in parallel"
  for __sb_t in $__sb_tools; do
    __sb_url=$(_reg_url "$__sb_t")
    if [ -z "$__sb_url" ]; then
      printf 'no_url\n' > "$__sb_workdir/$__sb_t.status"
      continue
    fi
    __sb_ext=$(_reg_field "$__sb_t" ARCHIVE)
    case "$__sb_ext" in
      none) __sb_suffix="" ;;
      *) __sb_suffix=".$__sb_ext" ;;
    esac
    __sb_dest="$__sb_workdir/$__sb_t$__sb_suffix"
    # Background subshell. stdout/stderr piped to per-tool log so parallel
    # output doesn't interleave.
    (
      if curl --fail --silent --show-error --location \
        --retry 3 --retry-delay 2 --connect-timeout 15 \
        -o "$__sb_dest" "$__sb_url" 2> "$__sb_workdir/$__sb_t.fetch.log"; then
        printf 'ok\n%s\n' "$__sb_dest" > "$__sb_workdir/$__sb_t.status"
      else
        printf 'fetch_failed\n%s\n' "$__sb_url" > "$__sb_workdir/$__sb_t.status"
      fi
    ) &
  done
  wait
  # Summary line per tool so the operator can see what happened.
  for __sb_t in $__sb_tools; do
    __sb_status=$(head -n 1 "$__sb_workdir/$__sb_t.status" 2> /dev/null)
    case "$__sb_status" in
      ok)
        __sb_size=$(wc -c < "$(sed -n '2p' "$__sb_workdir/$__sb_t.status")" 2> /dev/null || echo 0)
        log "  $__sb_t: fetched ($((__sb_size / 1024)) KB)"
        ;;
      no_url)
        log "  $__sb_t: no upstream URL for $ARCH/$LIBC; will fall back to distro pkg"
        ;;
      fetch_failed)
        warn "  $__sb_t: fetch failed; will fall back to distro pkg"
        ;;
    esac
  done
}

# --- install phase ------------------------------------------------------------

# registry_install_all TOOLS WORKDIR
#   For each tool in TOOLS: extract its fetched archive, install the binary,
#   run its smoke test. On any failure (including no_url), drop to pkg_install.
registry_install_all() {
  __sb_tools=$1
  __sb_workdir=$2
  __sb_failed=""

  __sb_terminal=""
  for __sb_t in $__sb_tools; do
    # Use && / || idiom so set -e doesn't fire on a return 2 from
    # _reg_install_one; we explicitly want to keep going.
    __sb_rc=0
    _reg_install_one "$__sb_t" "$__sb_workdir" || __sb_rc=$?
    case $__sb_rc in
      0) ;;                                        # success
      2) __sb_terminal="$__sb_terminal $__sb_t" ;; # hash/sig mismatch — no fallback
      *) __sb_failed="$__sb_failed $__sb_t" ;;     # soft failure — try distro pkg
    esac
  done

  if [ -n "$__sb_failed" ]; then
    log "Registry: distro fallback for:$__sb_failed"
    for __sb_t in $__sb_failed; do
      _reg_fallback "$__sb_t" || warn "$__sb_t: distro fallback also failed"
    done
  fi

  if [ -n "$__sb_terminal" ]; then
    err "Registry: terminal verification failure for:$__sb_terminal"
    err "  These tools were NOT installed via fallback (intentional)."
    err "  Investigate the source of the byte mismatch before re-running."
    return 1
  fi
}

# _reg_install_one TOOL WORKDIR
_reg_install_one() {
  __sb_t=$1
  __sb_workdir=$2

  # Idempotency: if our INSTALL_AS file already exists AND the smoke test
  # passes, skip extract+install. We deliberately check the target path,
  # not just `command -v`, because a distro pkg may have provided the
  # binary at /usr/bin/ — we still want OUR pinned version at
  # /usr/local/bin/ to shadow it. Symlinks are re-applied either way.
  __sb_smoke=$(_reg_field "$__sb_t" SMOKE)
  __sb_install_as=$(_reg_field "$__sb_t" INSTALL_AS)
  if [ -e "$__sb_install_as" ] && [ -n "$__sb_smoke" ] &&
    sh -c "$__sb_smoke" > /dev/null 2>&1; then
    log "  $__sb_t: already installed; skipping (ensuring symlinks)"
    _reg_apply_symlinks "$__sb_t"
    return 0
  fi

  __sb_statusfile="$__sb_workdir/$__sb_t.status"
  if [ ! -f "$__sb_statusfile" ]; then
    warn "  $__sb_t: no fetch status (was registry_fetch_all called?)"
    return 1
  fi
  __sb_status=$(head -n 1 "$__sb_statusfile")
  case "$__sb_status" in
    ok) ;;
    *) return 1 ;;
  esac
  __sb_archive=$(sed -n '2p' "$__sb_statusfile")
  if [ ! -s "$__sb_archive" ]; then
    warn "  $__sb_t: fetched archive missing or empty"
    return 1
  fi

  # Hash-pin verification — runs between fetch-success and extract.
  # Empty pin = skip silently (lets the engine ship before all tools are
  # pinned). Any mismatch is terminal: we deliberately do NOT fall back to
  # the distro package on a hash failure, because byte-level disagreement
  # between what we recorded in registry.sh and what the upstream URL now
  # serves is exactly the supply-chain signal we want operators to see.
  #
  # We check every pinned algorithm — both must agree if both are pinned.
  # Independent algorithm families (SHA-2/256 + SHA-2/512) catch a class of
  # collision-style attacks that a single algorithm wouldn't.
  __sb_hash_summary=""
  for __sb_algo in sha256 sha512; do
    __sb_expected_h=$(_reg_hash "$__sb_t" "$__sb_algo")
    [ -n "$__sb_expected_h" ] || continue
    __sb_actual_h=$("${__sb_algo}sum" "$__sb_archive" 2> /dev/null | cut -d' ' -f1)
    if [ -z "$__sb_actual_h" ]; then
      err "  $__sb_t: ${__sb_algo}sum unavailable — cannot verify pin"
      return 1
    fi
    if [ "$__sb_actual_h" != "$__sb_expected_h" ]; then
      err "  $__sb_t: $(printf '%s' "$__sb_algo" | tr '[:lower:]' '[:upper:]') MISMATCH"
      err "    expected: $__sb_expected_h"
      err "    got:      $__sb_actual_h"
      err "    aborting install (no distro-pkg fallback on hash failure)"
      return 2
    fi
    __sb_hash_summary="$__sb_hash_summary $__sb_algo ✓"
  done
  if [ -n "$__sb_hash_summary" ]; then
    log "  $__sb_t:$__sb_hash_summary"
  fi

  # Upstream signature/checksums cross-check (lib/registry_sigverify.sh).
  # rc=0 verified, rc=1 mismatch/fetch failure (terminal — no fallback),
  # rc=2 no SIG_TYPE declared for this tool (silent skip).
  __sb_sv_rc=0
  _reg_verify_signature "$__sb_t" "$__sb_archive" || __sb_sv_rc=$?
  case $__sb_sv_rc in
    0 | 2) ;;
    *)
      err "  $__sb_t: upstream signature/sums verification failed"
      return 2
      ;;
  esac

  __sb_ext=$(_reg_field "$__sb_t" ARCHIVE)
  __sb_bin_in_archive=$(_reg_bin_in_archive "$__sb_t")
  __sb_install_as=$(_reg_field "$__sb_t" INSTALL_AS)

  __sb_tmp=$(mktemp -d)
  __sb_bin_path=""
  case "$__sb_ext" in
    tar.gz)
      tar -xzf "$__sb_archive" -C "$__sb_tmp" 2> /dev/null || {
        warn "  $__sb_t: tar -xzf failed"
        rm -rf "$__sb_tmp"
        return 1
      }
      __sb_bin_path="$__sb_tmp/$__sb_bin_in_archive"
      ;;
    tar.xz)
      tar -xJf "$__sb_archive" -C "$__sb_tmp" 2> /dev/null || {
        warn "  $__sb_t: tar -xJf failed"
        rm -rf "$__sb_tmp"
        return 1
      }
      __sb_bin_path="$__sb_tmp/$__sb_bin_in_archive"
      ;;
    zip)
      if ! has_cmd unzip; then
        warn "  $__sb_t: unzip not available"
        rm -rf "$__sb_tmp"
        return 1
      fi
      unzip -q -o "$__sb_archive" -d "$__sb_tmp" 2> /dev/null || {
        warn "  $__sb_t: unzip failed"
        rm -rf "$__sb_tmp"
        return 1
      }
      __sb_bin_path="$__sb_tmp/$__sb_bin_in_archive"
      ;;
    gz)
      # Single-file gzip: asset itself is the binary, gzipped.
      gunzip -c "$__sb_archive" > "$__sb_tmp/$__sb_t" 2> /dev/null || {
        warn "  $__sb_t: gunzip failed"
        rm -rf "$__sb_tmp"
        return 1
      }
      __sb_bin_path="$__sb_tmp/$__sb_t"
      ;;
    none)
      # Raw binary download — the archive IS the binary.
      __sb_bin_path="$__sb_archive"
      ;;
    *)
      warn "  $__sb_t: unknown archive type '$__sb_ext'"
      rm -rf "$__sb_tmp"
      return 1
      ;;
  esac

  if [ ! -e "$__sb_bin_path" ]; then
    warn "  $__sb_t: binary not found at $__sb_bin_path inside archive"
    rm -rf "$__sb_tmp"
    return 1
  fi

  sudo_run install -m 0755 "$__sb_bin_path" "$__sb_install_as" || {
    warn "  $__sb_t: install -m 0755 failed"
    rm -rf "$__sb_tmp"
    return 1
  }

  # Tools that ship a full tree (lib/share/bin) — e.g. neovim — need the
  # whole top-level dir copied under /usr/local/ so the binary's runtime
  # data (lua plugins, parsers, locale files) is found.
  if [ "$(_reg_field "$__sb_t" EXTRA_ROOT_INSTALL)" = 1 ]; then
    __sb_topdir=$(printf '%s' "$__sb_bin_in_archive" | cut -d/ -f1)
    if [ -n "$__sb_topdir" ] && [ -d "$__sb_tmp/$__sb_topdir" ]; then
      sudo_run rm -rf "/usr/local/$__sb_topdir"
      sudo_run cp -a "$__sb_tmp/$__sb_topdir" "/usr/local/$__sb_topdir"
      sudo_run ln -sf "/usr/local/$__sb_topdir/bin/$(basename "$__sb_install_as")" \
        "$__sb_install_as"
    fi
  fi

  # Extra co-located binaries (e.g. qsvlite, qsvdp alongside qsv).
  __sb_extra=$(_reg_field "$__sb_t" EXTRA_BINS)
  if [ -n "$__sb_extra" ]; then
    __sb_install_dir=$(dirname "$__sb_install_as")
    __sb_bin_dir=$(dirname "$__sb_bin_path")
    for __sb_eb in $__sb_extra; do
      if [ -f "$__sb_bin_dir/$__sb_eb" ]; then
        sudo_run install -m 0755 "$__sb_bin_dir/$__sb_eb" \
          "$__sb_install_dir/$__sb_eb"
      fi
    done
  fi

  _reg_apply_symlinks "$__sb_t"
  # Post-install hook (e.g. tealdeer cache prime, helix runtime/ copy,
  # fzf shell scripts). The hook runs BEFORE we clean up the tmp dir so
  # it can read extra files out of the extracted archive — REGISTRY_TMP_DIR
  # is the per-tool tmp path, REGISTRY_TOOL is the lowercase tool name.
  __sb_hook=$(_reg_field "$__sb_t" POSTINSTALL_HOOK)
  if [ -n "$__sb_hook" ]; then
    # Exported so hooks defined in lib/tools/<tool>.sh can read them.
    # shellcheck disable=SC2034  # consumed by sourced hook functions
    REGISTRY_TMP_DIR=$__sb_tmp
    # shellcheck disable=SC2034
    REGISTRY_TOOL=$__sb_t
    export REGISTRY_TMP_DIR REGISTRY_TOOL
    "$__sb_hook" || warn "  $__sb_t: post-install hook returned non-zero"
  fi

  rm -rf "$__sb_tmp"

  # Smoke test the installed binary.
  if [ -n "$__sb_smoke" ] && ! sh -c "$__sb_smoke" > /dev/null 2>&1; then
    warn "  $__sb_t: installed but smoke test failed: $__sb_smoke"
    return 1
  fi

  log "  $__sb_t: installed ($(_reg_field "$__sb_t" VERSION))"
  return 0
}

# _reg_apply_symlinks TOOL
#   Creates ${TOOL}_SYMLINKS entries pointing at ${TOOL}_INSTALL_AS. Idempotent
#   (ln -sf). Runs whether the install was fresh or the registry skipped due to
#   an existing distro-pkg copy — so e.g. `pass -> gopass` is created on Alpine
#   even when apk's gopass package was already there.
_reg_apply_symlinks() {
  __sb_t=$1
  __sb_symlinks=$(_reg_field "$__sb_t" SYMLINKS)
  [ -n "$__sb_symlinks" ] || return 0
  __sb_install_as=$(_reg_field "$__sb_t" INSTALL_AS)
  __sb_install_base=$(basename "$__sb_install_as")
  # Resolve the actual binary path. If INSTALL_AS exists, use it; otherwise
  # (registry skipped because a distro pkg already provided the binary at,
  # say, /usr/bin/gopass) `command -v` finds the real path.
  if [ -e "$__sb_install_as" ]; then
    __sb_target="$__sb_install_as"
  else
    __sb_target=$(command -v "$__sb_install_base" 2> /dev/null || echo "")
  fi
  if [ -z "$__sb_target" ]; then
    warn "  $__sb_t: can't apply symlinks — target binary not found"
    return 0
  fi
  __sb_install_dir=$(dirname "$__sb_install_as")
  for __sb_sl in $__sb_symlinks; do
    # Use absolute target so the symlink works regardless of which dir
    # the apk/apt/dnf landed the binary in.
    sudo_run ln -sf "$__sb_target" "$__sb_install_dir/$__sb_sl"
  done
}

# _reg_fallback TOOL
#   Try pkg_install for the tool's distro package name (defaults to lowercase
#   tool name; can be overridden via ${TOOL}_FALLBACK_PKG).
_reg_fallback() {
  __sb_t=$1
  __sb_fallback=$(_reg_field "$__sb_t" FALLBACK_PKG)
  [ -n "$__sb_fallback" ] || __sb_fallback="$__sb_t"
  pkg_install "$__sb_fallback" > /dev/null 2>&1 || return 1
  __sb_smoke=$(_reg_field "$__sb_t" SMOKE)
  if [ -n "$__sb_smoke" ] && sh -c "$__sb_smoke" > /dev/null 2>&1; then
    log "  $__sb_t: installed via distro pkg ($__sb_fallback)"
    return 0
  fi
  return 1
}
