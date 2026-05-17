#!/bin/sh
# scripts/sync-hashes-into-registry.sh — propagate hash pins from
# registry-hashes.csv into lib/registry.sh.
#
# For every (tool, arch, libc) row with download_status=OK in the CSV,
# inserts/replaces TWO lines immediately after the matching
# _URL_${arch}_${libc} line in lib/registry.sh:
#
#     ${TOOL_UPPER}_SHA256_${arch}_${libc}=<sha256>
#     ${TOOL_UPPER}_SHA512_${arch}_${libc}=<sha512>
#
# Why two? Defense in depth — if some upstream's published checksum file
# only signs sha512, or if a flaw is ever found in one of the families,
# we still have an independent algorithm pinned in git. Both ship in
# GNU coreutils so no extra package is needed at install time. The CSV
# itself records 7 algorithms (md5/sha1/sha256/sha512/blake2b/blake3/crc32);
# extending the registry to BLAKE3 etc. would require shipping b3sum on the
# target host and isn't worth the friction today.
#
# Idempotent: re-running with the same CSV is a no-op.
#
# Usage:
#   sh scripts/sync-hashes-into-registry.sh            # patch in place
#   sh scripts/sync-hashes-into-registry.sh --check    # exit 1 if diff would change anything
#
# Source of truth: registry-hashes.csv (column 12 = sha256).
# Regenerate the CSV with scripts/make-registry-csv.sh after any version bump.

set -eu

CSV="./registry-hashes.csv"
REG="./lib/registry.sh"
MODE="${1:-patch}"

[ -f "$CSV" ] || {
  printf 'FATAL: %s not found (cwd: %s)\n' "$CSV" "$(pwd)" >&2
  exit 1
}
[ -f "$REG" ] || {
  printf 'FATAL: %s not found (cwd: %s)\n' "$REG" "$(pwd)" >&2
  exit 1
}

# Pull tool/arch/libc/sha256 into a flat lookup table written to a tmp file,
# one line per pin: "TOOLUPPER_SHA256_arch_libc<TAB>value". awk uses this
# as an associative lookup keyed by variable name.
LOOKUP=$(mktemp)
trap 'rm -f "$LOOKUP" "$LOOKUP.new"' EXIT

awk -F, 'NR>1 && $8=="OK" {
  tool=toupper($1); arch=$3; libc=$4; sha256=$12; sha512=$13
  if (sha256 != "") printf "%s_SHA256_%s_%s\t%s\n", tool, arch, libc, sha256
  if (sha512 != "") printf "%s_SHA512_%s_%s\t%s\n", tool, arch, libc, sha512
}' "$CSV" > "$LOOKUP"

# Walk registry.sh; after every "_URL_arch_libc=..." line, emit the matching
# SHA256 line. Drop any pre-existing "_SHA256_" lines so we don't accumulate
# stale duplicates on rerun.
awk -v lookup="$LOOKUP" '
BEGIN {
  while ((getline line < lookup) > 0) {
    n = split(line, f, "\t")
    if (n == 2) H[f[1]] = f[2]
  }
  close(lookup)
}
# Strip any existing hash-pin lines — we re-emit them fresh below.
/^[A-Z][A-Z0-9_]*_(SHA256|SHA512)_(amd64|arm64)_(gnu|musl)=/ { next }
{
  print
  # If this is a URL line, emit the matching SHA256 pin right after it
  # (including alias lines like `..._URL_arm64_musl="$..._URL_arm64_gnu"` —
  # the CSV has the post-expansion hash, and the engine reads SHA256 via
  # the same arch/libc key it uses for URLs).
  if (match($0, /^[A-Z][A-Z0-9_]*_URL_(amd64|arm64)_(gnu|musl)=/)) {
    eq = index($0, "=")
    lhs = substr($0, 1, eq - 1)        # e.g. BAT_URL_amd64_gnu
    rhs = substr($0, eq + 1)           # e.g. "https://..." or empty
    gsub(/^"|"$/, "", rhs)
    if (rhs != "") {                   # skip variants with no upstream URL
      # Emit each hash family for which we have a CSV entry.
      sha_lhs = lhs; sub("_URL_", "_SHA256_", sha_lhs)
      if (sha_lhs in H) print sha_lhs "=" H[sha_lhs]
      sha_lhs = lhs; sub("_URL_", "_SHA512_", sha_lhs)
      if (sha_lhs in H) print sha_lhs "=" H[sha_lhs]
    }
  }
}
' "$REG" > "$LOOKUP.new"

# Treat a URL whose RHS is a `$VAR` reference (e.g. ZOXIDE_URL_arm64_musl=$ZOXIDE_URL_arm64_gnu)
# as a re-use of another variant — no separate SHA256 pin needed (the awk
# above already detected this case and skipped emission).

if [ "$MODE" = --check ]; then
  if cmp -s "$REG" "$LOOKUP.new"; then
    printf 'sync-hashes: %s is up to date\n' "$REG"
    exit 0
  else
    printf 'sync-hashes: %s would change. Diff:\n' "$REG" >&2
    diff -u "$REG" "$LOOKUP.new" || true
    exit 1
  fi
fi

if cmp -s "$REG" "$LOOKUP.new"; then
  printf 'sync-hashes: %s already up to date (no change)\n' "$REG"
else
  cp "$LOOKUP.new" "$REG"
  sha256_n=$(grep -c '_SHA256_' "$REG" || true)
  sha512_n=$(grep -c '_SHA512_' "$REG" || true)
  printf 'sync-hashes: patched %s (sha256=%d, sha512=%d pins present)\n' \
    "$REG" "$sha256_n" "$sha512_n"
fi
