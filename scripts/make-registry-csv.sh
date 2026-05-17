#!/bin/sh
# shellcheck disable=SC2034,SC2310
#
# scripts/make-registry-csv.sh — download every package listed in
# lib/registry.sh and produce a provenance CSV with a full hash suite
# (MD5, SHA1, SHA256, SHA512, BLAKE2b, BLAKE3, cksum/CRC-32).
#
# Usage:  cd <repo-root> && sh scripts/make-registry-csv.sh
#
# Output:  ./registry-hashes.csv
#
# Requires: curl, date, md5sum, sha1sum, sha256sum, sha512sum, b2sum,
#           b3sum, cksum — all present on a typical Ubuntu 22.04+/Debian
#           workstation.

set -eu

# ---------------------------------------------------------------------------
# Source registry  (pure data — variable assignments only, no side effects)
# ---------------------------------------------------------------------------
. ./lib/registry.sh

# ---------------------------------------------------------------------------
# Pre-flight: verify required commands exist
# ---------------------------------------------------------------------------
for _cmd in curl date md5sum sha1sum sha256sum sha512sum b2sum b3sum cksum; do
  if ! command -v "${_cmd}" > /dev/null 2>&1; then
    printf 'FATAL: required command not found: %s\n' "${_cmd}" >&2
    exit 1
  fi
done

# ---------------------------------------------------------------------------
# Helpers  (strict POSIX sh — no arrays, no local, no $(<file))
# ---------------------------------------------------------------------------

# __val  —  indirect variable expansion:  __val=$($1)
__val=
_getvar() {
  eval "__val=\"\${$1:-}\""
}

# __hash  —  compute one hash for a file.  Usage: _hash_file <algo> <path>
# Supported: md5 sha1 sha256 sha512 blake2b blake3 crc32
__hash=
_hash_file() {
  __algo=$1
  __file=$2
  __line=

  case "${__algo}" in
    md5) __line=$(md5sum "${__file}" 2> /dev/null) || return 1 ;;
    sha1) __line=$(sha1sum "${__file}" 2> /dev/null) || return 1 ;;
    sha256) __line=$(sha256sum "${__file}" 2> /dev/null) || return 1 ;;
    sha512) __line=$(sha512sum "${__file}" 2> /dev/null) || return 1 ;;
    blake2b) __line=$(b2sum "${__file}" 2> /dev/null) || return 1 ;;
    blake3) __line=$(b3sum "${__file}") || return 1 ;;
    crc32) __line=$(cksum "${__file}") || return 1 ;;
    *) return 1 ;;
  esac

  __hash="${__line%% *}"
  return 0
}

# ---------------------------------------------------------------------------
# Set up working directory & output file
# ---------------------------------------------------------------------------
WORKDIR="${TMPDIR:-/tmp}/registry-hashes.$$"
mkdir -p "${WORKDIR}"
trap 'rm -rf "${WORKDIR}"' EXIT

OUTFILE="./registry-hashes.csv"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# CSV header
printf '%s\n' \
  'tool,version,arch,libc,url,archive_type,download_timestamp,download_status,size_bytes,md5,sha1,sha256,sha512,blake2b,blake3,crc32' \
  > "${OUTFILE}"

# ---------------------------------------------------------------------------
# Main loop — iterate every tool x (amd64_gnu, amd64_musl, arm64_gnu, arm64_musl)
# ---------------------------------------------------------------------------
for _tool in ${REGISTRY_TOOLS}; do
  # Upper-case prefix for registry variable names
  _pfx=$(printf '%s' "${_tool}" | tr '[:lower:]' '[:upper:]')

  _getvar "${_pfx}_VERSION"
  _version="${__val}"

  _getvar "${_pfx}_ARCHIVE"
  _archive="${__val}"

  for _variant in amd64_gnu amd64_musl arm64_gnu arm64_musl; do
    _getvar "${_pfx}_URL_${_variant}"
    _url="${__val}"
    [ -z "${_url}" ] && continue

    # Derive arch / libc from the variant label
    case "${_variant}" in
      amd64_*) _arch="amd64" ;;
      arm64_*) _arch="arm64" ;;
      *) _arch="" ;;
    esac
    case "${_variant}" in
      *_gnu) _libc="gnu" ;;
      *_musl) _libc="musl" ;;
      *) _libc="" ;;
    esac

    printf '  [%s] downloading %s/%s ... ' "${_tool}" "${_arch}" "${_libc}"

    # Derive local filename from the URL (basename of the path component)
    _fname=
    case "${_url}" in
      */*) _fname=$(printf '%s' "${_url}" | sed 's|.*/||') ;;
      *) _fname="${_tool}_${_variant}" ;;
    esac

    _dest="${WORKDIR}/${_fname}"

    # Reset per-download state
    _dl_status="OK"
    _size=
    _md5=
    _sha1=
    _sha256=
    _sha512=
    _blake2b=
    _blake3=
    _crc32=

    if curl -fsSL -o "${_dest}" "${_url}" 2> /dev/null; then
      _size=$(wc -c < "${_dest}")
      _size="${_size:-0}"

      if _hash_file md5 "${_dest}"; then _md5="${__hash}"; fi
      if _hash_file sha1 "${_dest}"; then _sha1="${__hash}"; fi
      if _hash_file sha256 "${_dest}"; then _sha256="${__hash}"; fi
      if _hash_file sha512 "${_dest}"; then _sha512="${__hash}"; fi
      if _hash_file blake2b "${_dest}"; then _blake2b="${__hash}"; fi
      if _hash_file blake3 "${_dest}"; then _blake3="${__hash}"; fi
      if _hash_file crc32 "${_dest}"; then _crc32="${__hash}"; fi

      printf 'OK (%s bytes)\n' "${_size}"
    else
      _dl_status="FAILED"
      printf 'FAILED\n'
    fi

    # Write CSV row (URL quoted for CSV safety)
    {
      printf '%s,%s,%s,%s,' \
        "${_tool}" "${_version}" "${_arch}" "${_libc}"
      printf '"%s",' "${_url}"
      printf '%s,%s,%s,%s,' \
        "${_archive}" "${TIMESTAMP}" "${_dl_status}" "${_size}"
      printf '%s,%s,%s,%s,%s,%s,%s\n' \
        "${_md5}" "${_sha1}" "${_sha256}" "${_sha512}" \
        "${_blake2b}" "${_blake3}" "${_crc32}"
    } >> "${OUTFILE}"
  done
done

printf '\nDone.  Output written to %s\n' "${OUTFILE}"
