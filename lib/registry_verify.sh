#!/bin/sh
# lib/registry_verify.sh — post-install sanity check.
#
# For every tool in $REGISTRY_TOOLS, runs its smoke command (the one declared
# via ${TOOL}_SMOKE in lib/registry.sh), parses a version string out of the
# output, and compares to the pinned ${TOOL}_VERSION. Prints an aligned
# summary table so the operator can spot drift at a glance.
#
# Default: warn-only — a mismatch is informational (it usually means the
# upstream URL was unset for the host's (arch, libc) and we landed on a
# distro-pkg fallback, which is a legit but worth-flagging outcome).
# Set SHELL_BLING_STRICT_VERSIONS=1 to turn mismatches into a hard install
# failure (used in CI: docker/entrypoint.sh + the Jenkins matrix set this).
#
# Defaults to the regex `[0-9]+\.[0-9]+(\.[0-9]+)?` for version extraction;
# override per tool via ${TOOL}_VERSION_PATTERN in the registry if a tool's
# `--version` output puts the number somewhere unusual.

# registry_verify_all TOOLS  → print summary table; exit non-zero on mismatch
# only if SHELL_BLING_STRICT_VERSIONS=1.
registry_verify_all() {
  __sb_tools=$1
  __sb_total=0
  __sb_pass=0
  __sb_fail=0
  __sb_rows=""
  __sb_shadows=""

  for __sb_t in $__sb_tools; do
    __sb_total=$((__sb_total + 1))
    __sb_expected=$(_reg_field "$__sb_t" VERSION)
    __sb_smoke=$(_reg_field "$__sb_t" SMOKE)
    __sb_install_as=$(_reg_field "$__sb_t" INSTALL_AS)
    __sb_pattern=$(_reg_field "$__sb_t" VERSION_PATTERN)
    [ -n "$__sb_pattern" ] || __sb_pattern='[0-9][0-9]*\.[0-9][0-9]*\(\.[0-9][0-9]*\)*'

    # Always run the smoke with INSTALL_AS's dir first in PATH. We want to
    # test what we actually installed; without this, a user-local copy
    # earlier in PATH (eg ~/.local/bin/fd from cargo, ~/.fzf/bin/fzf from
    # the upstream install script) is what gets tested and a perfectly
    # good install reports as "drift". PATH shadowing is surfaced
    # separately below so the operator can see *that* it's happening.
    __sb_smoke_dir=""
    case "$__sb_install_as" in
      */*) __sb_smoke_dir=$(dirname -- "$__sb_install_as") ;;
    esac
    __sb_smoke_path="${__sb_smoke_dir:+$__sb_smoke_dir:}$PATH"

    # Shadow check (informational): if the bare binary name resolves to a
    # path other than INSTALL_AS, the user's shell will run a different
    # copy than the one we just installed. Often legitimate (cargo-installed
    # fd, ~/.fzf install) — never silent.
    __sb_smoke_bin=$(printf '%s' "$__sb_smoke" | awk '{print $1}')
    if [ -n "$__sb_smoke_bin" ] && [ -n "$__sb_install_as" ]; then
      __sb_resolved=$(command -v "$__sb_smoke_bin" 2> /dev/null || true)
      if [ -n "$__sb_resolved" ] && [ "$__sb_resolved" != "$__sb_install_as" ]; then
        __sb_shadows="$__sb_shadows  $__sb_smoke_bin: shadowed in PATH by $__sb_resolved (installed at $__sb_install_as)\n"
      fi
    fi

    if [ -z "$__sb_smoke" ]; then
      __sb_rows="$__sb_rows$(printf '  %-12s expected %-10s no SMOKE defined  -' \
        "$__sb_t" "$__sb_expected")\n"
      __sb_fail=$((__sb_fail + 1))
      continue
    fi

    # VERSION_PATTERN=skip: smoke-test only; tool doesn't expose its tag
    # (gron's --version literally prints "gron version dev"). Trust the
    # URL — if smoke passed and INSTALL_AS exists, we got what we asked for.
    if [ "$__sb_pattern" = skip ]; then
      if PATH="$__sb_smoke_path" sh -c "$__sb_smoke" > /dev/null 2>&1; then
        __sb_rows="$__sb_rows$(printf '  %-12s expected %-10s smoke ok (no ver) ✓' \
          "$__sb_t" "$__sb_expected")\n"
        __sb_pass=$((__sb_pass + 1))
      else
        __sb_rows="$__sb_rows$(printf '  %-12s expected %-10s smoke FAILED     ✗' \
          "$__sb_t" "$__sb_expected")\n"
        __sb_fail=$((__sb_fail + 1))
      fi
      continue
    fi

    # Capture combined stdout+stderr — some tools (eg micro -version) emit on stderr.
    # Track the exit code separately: a tool that crashed on --version did NOT
    # install at the wrong version, it failed to install. Parsing the error
    # text would mistake "GLIBC_2.18 not found" for "installed version 2.18"
    # (every Rust binary on CentOS 7's glibc 2.17 used to be misreported that
    # way). Classify nonzero rc as a smoke-failure row instead.
    # `|| __sb_rc=$?` keeps the failure rc without tripping `set -e` in
    # busybox ash (which exits the parent on `var=$(failing)`).
    __sb_rc=0
    __sb_out=$(PATH="$__sb_smoke_path" sh -c "$__sb_smoke" 2>&1) || __sb_rc=$?
    if [ "$__sb_rc" -ne 0 ]; then
      __sb_rows="$__sb_rows$(printf '  %-12s expected %-10s smoke FAILED (rc=%d) ✗' \
        "$__sb_t" "$__sb_expected" "$__sb_rc")\n"
      __sb_fail=$((__sb_fail + 1))
      continue
    fi
    __sb_actual=$(printf '%s\n' "$__sb_out" | grep -o "$__sb_pattern" | head -n 1)

    if [ -z "$__sb_actual" ]; then
      __sb_rows="$__sb_rows$(printf '  %-12s expected %-10s no version parsed  ✗' \
        "$__sb_t" "$__sb_expected")\n"
      __sb_fail=$((__sb_fail + 1))
    elif [ "$__sb_actual" = "$__sb_expected" ]; then
      __sb_rows="$__sb_rows$(printf '  %-12s expected %-10s got %-10s    ✓' \
        "$__sb_t" "$__sb_expected" "$__sb_actual")\n"
      __sb_pass=$((__sb_pass + 1))
    else
      __sb_rows="$__sb_rows$(printf '  %-12s expected %-10s got %-10s    ✗' \
        "$__sb_t" "$__sb_expected" "$__sb_actual")\n"
      __sb_fail=$((__sb_fail + 1))
    fi
  done

  echo
  echo "==> Post-install verification:"
  printf '%b' "$__sb_rows"
  printf '==> %d/%d tools at pinned version\n' "$__sb_pass" "$__sb_total"
  if [ -n "$__sb_shadows" ]; then
    echo
    warn "PATH shadowing detected — your shell will run these copies, not ours:"
    printf '%b' "$__sb_shadows" >&2
    warn "Fix by reordering PATH (put /usr/local/bin first) or removing the shadows."
  fi

  if [ "$__sb_fail" -gt 0 ] && [ "${SHELL_BLING_STRICT_VERSIONS:-0}" = 1 ]; then
    err "Version mismatch and SHELL_BLING_STRICT_VERSIONS=1 — failing install"
    return 1
  fi
  return 0
}
