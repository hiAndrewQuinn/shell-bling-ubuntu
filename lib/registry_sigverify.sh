#!/bin/sh
# lib/registry_sigverify.sh — cross-check an installed archive against an
# upstream-published checksums file.
#
# Today this implements one mechanism: `shasums-plain`. The engine fetches
# the upstream sums file (e.g. fzf_X.Y.Z_checksums.txt), looks up our
# asset's basename in it, and compares the published SHA256 to the bytes
# we already downloaded. Same-channel cross-reference: an attacker who can
# swap the binary can also swap the unsigned sums file. What it catches:
#
#   * Accidental corruption between our pin and what upstream currently
#     serves (silent re-publish, mirror skew, CDN flake).
#   * Upstream rotating an asset without publishing a CHANGELOG note.
#   * Discrepancy between what `make-registry-csv.sh` recorded and what
#     upstream's own release process recorded — same publisher should
#     agree with themselves.
#
# What it does NOT catch:
#   * A coordinated swap of both the binary and the sums file (no
#     cryptographic signature is involved).
#
# Real signature verification (`shasums-gpg`, minisign, cosign/sigstore)
# was investigated and dropped — see scripts/survey-upstream-signatures.sh
# output: of 22 tools in the registry, only gopass ships a PGP-signed
# checksums file, and its signing key has no chain of trust on standard
# keyservers. Hardcoding that fingerprint would be TOFU dressed up as
# cryptographic assurance, so we don't.
#
# Public entry point:
#   _reg_verify_signature TOOL ARCHIVE_PATH
#     returns 0 = verified
#     returns 1 = mismatch / fetch failure (terminal — engine refuses fallback)
#     returns 2 = no upstream sums file declared (silent skip)

# _reg_verify_signature TOOL ARCHIVE_PATH
_reg_verify_signature() {
  __sv_t=$1
  __sv_archive=$2

  __sv_type=$(_reg_field "$__sv_t" SIG_TYPE)
  case "$__sv_type" in
    "") return 2 ;; # no sig declared
    shasums-plain) _reg_sigverify_shasums_plain "$__sv_t" "$__sv_archive" ;;
    *)
      warn "  $__sv_t: unknown SIG_TYPE '$__sv_type' — skipping"
      return 2
      ;;
  esac
}

# _reg_sigverify_shasums_plain TOOL ARCHIVE_PATH
#   Download the upstream sums file, find our asset name in it, compare to
#   the actual SHA256 of ARCHIVE_PATH.
_reg_sigverify_shasums_plain() {
  __sv_t=$1
  __sv_archive=$2

  __sv_sums_url=$(_reg_field "$__sv_t" SIG_URL)
  if [ -z "$__sv_sums_url" ]; then
    return 2
  fi

  # Asset name to look up = basename of our actual download URL.
  __sv_dl_url=$(_reg_url "$__sv_t")
  __sv_asset_name=$(printf '%s' "$__sv_dl_url" | sed 's|.*/||')
  if [ -z "$__sv_asset_name" ]; then
    warn "  $__sv_t: could not derive asset name from URL"
    return 1
  fi

  __sv_sums_file=$(mktemp)
  if ! curl --fail --silent --location --max-time 30 \
    -o "$__sv_sums_file" "$__sv_sums_url"; then
    err "  $__sv_t: failed to fetch upstream sums file: $__sv_sums_url"
    rm -f "$__sv_sums_file"
    return 1
  fi

  # GNU coreutils sums-file format is "<hash><space><space|*><filename>".
  # `sha256sum -c` would do the matching for us if the file is in canonical
  # form, but some upstreams (jq) put just "hash filename" on one line per
  # asset, and we want a precise error message. Grep + cut is simpler.
  __sv_expected_sha=$(grep -F "  $__sv_asset_name" "$__sv_sums_file" 2> /dev/null | head -n 1 | cut -d' ' -f1)
  if [ -z "$__sv_expected_sha" ]; then
    # Some sums files use a single space + asterisk format ("hash *filename").
    __sv_expected_sha=$(grep -F " *$__sv_asset_name" "$__sv_sums_file" 2> /dev/null | head -n 1 | cut -d' ' -f1)
  fi
  if [ -z "$__sv_expected_sha" ]; then
    err "  $__sv_t: asset name '$__sv_asset_name' not found in upstream sums"
    err "    sums url: $__sv_sums_url"
    rm -f "$__sv_sums_file"
    return 1
  fi
  rm -f "$__sv_sums_file"

  __sv_actual_sha=$(sha256sum "$__sv_archive" 2> /dev/null | cut -d' ' -f1)
  if [ "$__sv_actual_sha" != "$__sv_expected_sha" ]; then
    err "  $__sv_t: upstream sums file disagrees with downloaded bytes"
    err "    upstream:   $__sv_expected_sha"
    err "    downloaded: $__sv_actual_sha"
    return 1
  fi

  log "  $__sv_t: upstream-sums ✓"
  return 0
}
