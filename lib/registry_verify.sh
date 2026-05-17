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

  for __sb_t in $__sb_tools; do
    __sb_total=$((__sb_total + 1))
    __sb_expected=$(_reg_field "$__sb_t" VERSION)
    __sb_smoke=$(_reg_field "$__sb_t" SMOKE)
    __sb_pattern=$(_reg_field "$__sb_t" VERSION_PATTERN)
    [ -n "$__sb_pattern" ] || __sb_pattern='[0-9][0-9]*\.[0-9][0-9]*\(\.[0-9][0-9]*\)*'

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
      if sh -c "$__sb_smoke" > /dev/null 2>&1; then
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
    __sb_out=$(sh -c "$__sb_smoke" 2>&1 || true)
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

  if [ "$__sb_fail" -gt 0 ] && [ "${SHELL_BLING_STRICT_VERSIONS:-0}" = 1 ]; then
    err "Version mismatch and SHELL_BLING_STRICT_VERSIONS=1 — failing install"
    return 1
  fi
  return 0
}
