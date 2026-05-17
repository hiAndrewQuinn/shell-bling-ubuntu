#!/bin/sh
# scripts/survey-upstream-signatures.sh — for every tool in the registry,
# query the GitHub release API and report every asset that looks like a
# signature or checksum file. Far more reliable than probing fixed names,
# because upstream naming is chaotic (jq uses sha256sum.txt, gh uses
# <tool>_<ver>_checksums.txt, etc.).
#
# Output: ./signature-survey.md — per-tool list of candidate sig/checksum
# assets, plus a hint at the verification mechanism (gpg / minisign /
# cosign / sha256sums-unsigned).
#
# Auth: uses $GH_TOKEN or `gh auth token` if available; falls back to
# anonymous (60 reqs/hr — fine, we have ~22 tools).
#
# Usage:  cd <repo-root> && sh scripts/survey-upstream-signatures.sh

set -eu

. ./lib/registry.sh

OUT=./signature-survey.md
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

TOKEN="${GH_TOKEN:-}"
if [ -z "$TOKEN" ] && command -v gh > /dev/null 2>&1; then
  TOKEN=$(gh auth token 2> /dev/null || true)
fi
AUTH_HEADER=""
if [ -n "$TOKEN" ]; then
  AUTH_HEADER="-H Authorization: Bearer ${TOKEN}"
fi

# Parse a release URL like
# https://github.com/owner/repo/releases/download/tag/asset
# into owner/repo and tag.
__owner_repo=
__tag=
_parse_url() {
  __owner_repo=$(printf '%s\n' "$1" | sed -n 's|^https://github.com/\([^/]*/[^/]*\)/releases/download/.*|\1|p')
  __tag=$(printf '%s\n' "$1" | sed -n 's|^https://github.com/[^/]*/[^/]*/releases/download/\([^/]*\)/.*|\1|p')
}

# Fetch release JSON for owner/repo + tag and emit one line per asset name.
_release_assets() {
  __or=$1
  __t=$2
  # shellcheck disable=SC2086  # word-splitting on AUTH_HEADER is intentional
  curl -fsSL --max-time 20 $AUTH_HEADER \
    -H 'Accept: application/vnd.github+json' \
    "https://api.github.com/repos/${__or}/releases/tags/${__t}" |
    grep -oE '"name":[[:space:]]*"[^"]*"' |
    sed 's/^"name":[[:space:]]*"//;s/"$//'
}

# Classify an asset name. Echoes a category tag:
#   gpg         — .asc / .gpg
#   minisign    — .minisig
#   sigstore    — .sigstore / .sig.cosign / .intoto.jsonl / .pem
#   sums-signed — looks like a checksum file accompanied by .asc/.sig
#   sums-plain  — checksum file with no companion signature
#   other       — none of the above
# Note: this function only classifies one name at a time; "sums-signed"
# requires that the caller has separately seen a *.asc/*.sig sibling.
_classify() {
  case "$1" in
    *.asc | *.gpg) echo gpg ;;
    *.minisig) echo minisign ;;
    *.sigstore | *.cosign.sig | *.intoto.jsonl | *.cert | *.pem) echo sigstore ;;
    *SHA256SUMS* | *checksums* | *sha256sum* | *SHASUMS256* | *shasums* | *checksum*)
      echo sums
      ;;
    *) echo other ;;
  esac
}

{
  printf '# Upstream signature survey\n\n'
  printf '_Probed %s via GitHub release API_\n\n' "$TS"
  printf 'Per tool: every release asset that looks like a signature\n'
  printf '(`.asc` / `.minisig` / `.sigstore` / etc.) or checksum file is\n'
  printf 'listed. **sums** with no companion **gpg/minisign/sigstore** entry\n'
  printf 'means an unsigned checksum file — not useful for verification on its own.\n\n'
} > "$OUT"

for tool in $REGISTRY_TOOLS; do
  pfx=$(printf '%s' "$tool" | tr '[:lower:]' '[:upper:]')
  eval "url=\"\${${pfx}_URL_amd64_gnu:-}\""
  [ -n "$url" ] || continue
  _parse_url "$url"
  [ -n "$__owner_repo" ] && [ -n "$__tag" ] || {
    printf '## %s — non-github URL, skipped\n\n' "$tool" >> "$OUT"
    continue
  }

  printf '  probing %s (%s @ %s)\n' "$tool" "$__owner_repo" "$__tag" >&2

  ASSETS=$(_release_assets "$__owner_repo" "$__tag" 2> /dev/null || true)
  [ -n "$ASSETS" ] || {
    printf '## %s — API call returned no assets\n\n' "$tool" >> "$OUT"
    continue
  }

  # Categorize. `|| true` neutralizes the inner non-zero exits (empty
  # lines, no matches) that would otherwise trip `set -e` at the top
  # level via command substitution.
  GPG=$(printf '%s\n' "$ASSETS" | grep -E '\.(asc|gpg)$' || true)
  MINI=$(printf '%s\n' "$ASSETS" | grep -E '\.minisig$' || true)
  SIGS=$(printf '%s\n' "$ASSETS" | grep -E '\.(sigstore|cosign\.sig|intoto\.jsonl|cert|pem)$' || true)
  SUMS=$(printf '%s\n' "$ASSETS" | grep -Ei 'sha256sum|sha256sums|shasums|checksum|sums' |
    grep -Ev '\.(asc|gpg|minisig|sigstore|cosign\.sig|intoto\.jsonl|cert|pem)$' || true)

  HAS_GPG="no"
  [ -n "$GPG" ] && HAS_GPG="yes"
  HAS_MINI="no"
  [ -n "$MINI" ] && HAS_MINI="yes"
  HAS_SIG="no"
  [ -n "$SIGS" ] && HAS_SIG="yes"
  HAS_SUM="no"
  [ -n "$SUMS" ] && HAS_SUM="yes"

  # Recommend mechanism.
  REC=none
  if [ "$HAS_MINI" = yes ]; then
    REC=minisign
  elif [ "$HAS_SIG" = yes ]; then
    REC=cosign/sigstore
  elif [ "$HAS_GPG" = yes ] && [ "$HAS_SUM" = yes ]; then
    REC=shasums-gpg
  elif [ "$HAS_GPG" = yes ]; then
    REC=gpg-per-asset
  elif [ "$HAS_SUM" = yes ]; then
    REC="sums-only (unsigned)"
  fi

  {
    printf '## %s (%s @ %s) — **%s**\n\n' "$tool" "$__owner_repo" "$__tag" "$REC"
    [ "$HAS_GPG" = yes ] && printf '* gpg:        %s\n' "$(echo "$GPG" | paste -sd, -)"
    [ "$HAS_MINI" = yes ] && printf '* minisign:   %s\n' "$(echo "$MINI" | paste -sd, -)"
    [ "$HAS_SIG" = yes ] && printf '* sigstore:   %s\n' "$(echo "$SIGS" | paste -sd, -)"
    [ "$HAS_SUM" = yes ] && printf '* checksums:  %s\n' "$(echo "$SUMS" | paste -sd, -)"
    [ "$REC" = none ] && printf '* (no signature or checksum assets)\n'
    printf '\n'
  } >> "$OUT"
done

printf '\nDone. Survey written to %s\n' "$OUT" >&2
