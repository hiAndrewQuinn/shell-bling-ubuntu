#!/bin/sh
# shellcheck disable=SC2034
# (Every assignment in this file is read indirectly via eval from
# lib/registry_install.sh; shellcheck can't see that, so suppress SC2034
# globally — the file is pure data by design.)
#
# lib/registry.sh — static-binary tool registry.
#
# PURE DATA. NO LOGIC.
#
# Consumed by lib/registry_install.sh via indirect (eval-based) lookup.
# Every entry is one block of `VAR=value` lines, prefixed with the tool's
# upper-cased name. Tokens are POSIX-safe: no functions, no `if`, no `case`,
# no commands, just variable assignments. Sourcing this file must produce
# only environment variables.
#
# Required fields per tool:
#   ${TOOL}_VERSION                    pinned upstream version (no leading "v")
#   ${TOOL}_URL_amd64_gnu              download URL for that (arch,libc)
#   ${TOOL}_URL_amd64_musl             (set to gnu URL if a single binary works on both)
#   ${TOOL}_URL_arm64_gnu              empty string = "no upstream binary, fall through"
#   ${TOOL}_URL_arm64_musl
#   ${TOOL}_ARCHIVE                    tar.gz | tar.xz | zip | gz | none
#                                      ("gz" = single-file gzip; "none" = raw binary)
#   ${TOOL}_BIN_IN_ARCHIVE             relative path of the binary inside the archive
#                                      ("." for raw binaries / single-file gzip)
#   ${TOOL}_INSTALL_AS                 absolute destination path on disk
#   ${TOOL}_SMOKE                      command to run after install (must exit 0)
#
# Optional fields:
#   ${TOOL}_FALLBACK_PKG               distro package name for pkg_install fallback
#                                      (defaults to the lowercase tool name)
#   ${TOOL}_POSTINSTALL_HOOK           function name (defined in lib/tools/<tool>.sh)
#                                      that the engine calls after a successful install
#   ${TOOL}_EXTRA_BINS                 space-separated extra binaries to install from
#                                      the archive (e.g. "qsvlite qsvdp" for qsv)
#
# Versions in this file were verified against the upstream releases pages on
# 2026-05-17. Bump via scripts/bump-registry.sh (planned in R4.3).

# ----- cheat ----- single-file gzip; the asset is the binary itself, gzipped.
CHEAT_VERSION=5.1.0
CHEAT_URL_amd64_gnu="https://github.com/cheat/cheat/releases/download/${CHEAT_VERSION}/cheat-linux-amd64.gz"
CHEAT_URL_amd64_musl="$CHEAT_URL_amd64_gnu"
CHEAT_URL_arm64_gnu="https://github.com/cheat/cheat/releases/download/${CHEAT_VERSION}/cheat-linux-arm64.gz"
CHEAT_URL_arm64_musl="$CHEAT_URL_arm64_gnu"
CHEAT_ARCHIVE=gz
CHEAT_BIN_IN_ARCHIVE=.
CHEAT_INSTALL_AS=/usr/local/bin/cheat
CHEAT_SMOKE="cheat --version"

# ----- eza ----- gnu and musl tarballs for both arches.
EZA_VERSION=0.23.4
EZA_URL_amd64_gnu="https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz"
EZA_URL_amd64_musl="https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-musl.tar.gz"
EZA_URL_arm64_gnu="https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_aarch64-unknown-linux-gnu.tar.gz"
EZA_URL_arm64_musl="$EZA_URL_arm64_gnu"
EZA_ARCHIVE=tar.gz
EZA_BIN_IN_ARCHIVE=./eza
EZA_INSTALL_AS=/usr/local/bin/eza
EZA_SMOKE="eza --version"

# ----- gh ----- official tarballs alongside the deb/rpm assets.
GH_VERSION=2.92.0
GH_URL_amd64_gnu="https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz"
GH_URL_amd64_musl="$GH_URL_amd64_gnu"
GH_URL_arm64_gnu="https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_arm64.tar.gz"
GH_URL_arm64_musl="$GH_URL_arm64_gnu"
GH_ARCHIVE=tar.gz
GH_BIN_IN_ARCHIVE="gh_${GH_VERSION}_linux_amd64/bin/gh"
# Per-arch path-inside-tarball differs; override below.
GH_BIN_IN_ARCHIVE_amd64="gh_${GH_VERSION}_linux_amd64/bin/gh"
GH_BIN_IN_ARCHIVE_arm64="gh_${GH_VERSION}_linux_arm64/bin/gh"
GH_INSTALL_AS=/usr/local/bin/gh
GH_SMOKE="gh --version"
GH_FALLBACK_PKG=github-cli

# ----- gopass ----- Go binary; gnu+musl tarballs published per arch.
GOPASS_VERSION=1.16.1
GOPASS_URL_amd64_gnu="https://github.com/gopasspw/gopass/releases/download/v${GOPASS_VERSION}/gopass-${GOPASS_VERSION}-linux-amd64.tar.gz"
GOPASS_URL_amd64_musl="$GOPASS_URL_amd64_gnu"
GOPASS_URL_arm64_gnu="https://github.com/gopasspw/gopass/releases/download/v${GOPASS_VERSION}/gopass-${GOPASS_VERSION}-linux-arm64.tar.gz"
GOPASS_URL_arm64_musl="$GOPASS_URL_arm64_gnu"
GOPASS_ARCHIVE=tar.gz
GOPASS_BIN_IN_ARCHIVE=gopass
GOPASS_INSTALL_AS=/usr/local/bin/gopass
GOPASS_SYMLINKS="pass" # /usr/local/bin/pass -> gopass (compat with existing pass muscle memory)
GOPASS_SMOKE="gopass --version"

# ----- lazygit ----- Go binary; one tarball runs on glibc and musl.
LAZYGIT_VERSION=0.61.1
LAZYGIT_URL_amd64_gnu="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_x86_64.tar.gz"
LAZYGIT_URL_amd64_musl="$LAZYGIT_URL_amd64_gnu"
LAZYGIT_URL_arm64_gnu="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_arm64.tar.gz"
LAZYGIT_URL_arm64_musl="$LAZYGIT_URL_arm64_gnu"
LAZYGIT_ARCHIVE=tar.gz
LAZYGIT_BIN_IN_ARCHIVE=lazygit
LAZYGIT_INSTALL_AS=/usr/local/bin/lazygit
LAZYGIT_SMOKE="lazygit --version"

# ----- lsd ----- gnu+musl tarballs, both arches.
LSD_VERSION=1.2.0
LSD_URL_amd64_gnu="https://github.com/lsd-rs/lsd/releases/download/v${LSD_VERSION}/lsd-v${LSD_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
LSD_URL_amd64_musl="https://github.com/lsd-rs/lsd/releases/download/v${LSD_VERSION}/lsd-v${LSD_VERSION}-x86_64-unknown-linux-musl.tar.gz"
LSD_URL_arm64_gnu="https://github.com/lsd-rs/lsd/releases/download/v${LSD_VERSION}/lsd-v${LSD_VERSION}-aarch64-unknown-linux-gnu.tar.gz"
LSD_URL_arm64_musl="$LSD_URL_arm64_gnu"
LSD_ARCHIVE=tar.gz
LSD_BIN_IN_ARCHIVE_amd64_gnu="lsd-v${LSD_VERSION}-x86_64-unknown-linux-gnu/lsd"
LSD_BIN_IN_ARCHIVE_amd64_musl="lsd-v${LSD_VERSION}-x86_64-unknown-linux-musl/lsd"
LSD_BIN_IN_ARCHIVE_arm64_gnu="lsd-v${LSD_VERSION}-aarch64-unknown-linux-gnu/lsd"
LSD_BIN_IN_ARCHIVE_arm64_musl="$LSD_BIN_IN_ARCHIVE_arm64_gnu"
LSD_BIN_IN_ARCHIVE="$LSD_BIN_IN_ARCHIVE_amd64_gnu" # fallback if engine doesn't find arch-specific
LSD_INSTALL_AS=/usr/local/bin/lsd
LSD_SMOKE="lsd --version"

# ----- micro ----- Go binary; only amd64 ships a -static variant for musl.
# arm64 ships one tarball; works on glibc and musl (Go binary).
MICRO_VERSION=2.0.15
MICRO_URL_amd64_gnu="https://github.com/zyedidia/micro/releases/download/v${MICRO_VERSION}/micro-${MICRO_VERSION}-linux64.tar.gz"
MICRO_URL_amd64_musl="https://github.com/zyedidia/micro/releases/download/v${MICRO_VERSION}/micro-${MICRO_VERSION}-linux64-static.tar.gz"
MICRO_URL_arm64_gnu="https://github.com/zyedidia/micro/releases/download/v${MICRO_VERSION}/micro-${MICRO_VERSION}-linux-arm64.tar.gz"
MICRO_URL_arm64_musl="$MICRO_URL_arm64_gnu"
MICRO_ARCHIVE=tar.gz
MICRO_BIN_IN_ARCHIVE="micro-${MICRO_VERSION}/micro"
MICRO_INSTALL_AS=/usr/local/bin/micro
MICRO_SMOKE="micro -version"

# ----- neovim ----- glibc-only tarballs (Alpine falls through to apk).
NEOVIM_VERSION=0.12.2
NEOVIM_URL_amd64_gnu="https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-x86_64.tar.gz"
NEOVIM_URL_amd64_musl="" # no musl build — engine falls through
NEOVIM_URL_arm64_gnu="https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-arm64.tar.gz"
NEOVIM_URL_arm64_musl=""
NEOVIM_ARCHIVE=tar.gz
NEOVIM_BIN_IN_ARCHIVE_amd64="nvim-linux-x86_64/bin/nvim"
NEOVIM_BIN_IN_ARCHIVE_arm64="nvim-linux-arm64/bin/nvim"
NEOVIM_BIN_IN_ARCHIVE="$NEOVIM_BIN_IN_ARCHIVE_amd64"
NEOVIM_INSTALL_AS=/usr/local/bin/nvim
NEOVIM_SMOKE="nvim --version"
NEOVIM_FALLBACK_PKG=neovim
# Neovim's release tarball ships an entire directory tree (bin/, lib/, share/)
# that the binary loads at runtime. The engine sees EXTRA_ROOT_INSTALL=1 and
# copies the whole top-level extracted dir under /usr/local/, then symlinks
# the bin. This avoids the AppImage-extract approach.
NEOVIM_EXTRA_ROOT_INSTALL=1

# ----- qsv ----- gnu-only on arm64; gnu+musl on amd64.
# Note: qsv's versions are unprefixed (no leading v); tag "20.0.0" — not "0.20.0".
# qsv's prebuilt -gnu binaries need glibc >= 2.38 — Debian 12 ships 2.36,
# Ubuntu 22.04 ships 2.35. The engine falls back to the -musl variant
# automatically when host glibc is older than QSV_GLIBC_MIN.
QSV_GLIBC_MIN=2.38
QSV_VERSION=20.0.0
QSV_URL_amd64_gnu="https://github.com/dathere/qsv/releases/download/${QSV_VERSION}/qsv-${QSV_VERSION}-x86_64-unknown-linux-gnu.zip"
QSV_URL_amd64_musl="https://github.com/dathere/qsv/releases/download/${QSV_VERSION}/qsv-${QSV_VERSION}-x86_64-unknown-linux-musl.zip"
QSV_URL_arm64_gnu="https://github.com/dathere/qsv/releases/download/${QSV_VERSION}/qsv-${QSV_VERSION}-aarch64-unknown-linux-gnu.zip"
QSV_URL_arm64_musl="" # not shipped upstream
QSV_ARCHIVE=zip
QSV_BIN_IN_ARCHIVE=qsv
QSV_EXTRA_BINS="qsvlite qsvdp"
QSV_INSTALL_AS=/usr/local/bin/qsv
QSV_SMOKE="qsv --version"

# ----- starship ----- arm64 ships musl-only; amd64 has both. Musl works on glibc.
STARSHIP_VERSION=1.25.1
STARSHIP_URL_amd64_gnu="https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-x86_64-unknown-linux-gnu.tar.gz"
STARSHIP_URL_amd64_musl="https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-x86_64-unknown-linux-musl.tar.gz"
STARSHIP_URL_arm64_gnu="https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-aarch64-unknown-linux-musl.tar.gz"
STARSHIP_URL_arm64_musl="$STARSHIP_URL_arm64_gnu"
STARSHIP_ARCHIVE=tar.gz
STARSHIP_BIN_IN_ARCHIVE=starship
STARSHIP_INSTALL_AS=/usr/local/bin/starship
STARSHIP_SMOKE="starship --version"

# ----- zoxide ----- musl-only Rust release; runs on glibc fine.
ZOXIDE_VERSION=0.9.9
ZOXIDE_URL_amd64_gnu="https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-x86_64-unknown-linux-musl.tar.gz"
ZOXIDE_URL_amd64_musl="$ZOXIDE_URL_amd64_gnu"
ZOXIDE_URL_arm64_gnu="https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-aarch64-unknown-linux-musl.tar.gz"
ZOXIDE_URL_arm64_musl="$ZOXIDE_URL_arm64_gnu"
ZOXIDE_ARCHIVE=tar.gz
ZOXIDE_BIN_IN_ARCHIVE=zoxide
ZOXIDE_INSTALL_AS=/usr/local/bin/zoxide
ZOXIDE_SMOKE="zoxide --version"

# ----- tealdeer ----- musl-static raw binary; no archive.
# Installed as /usr/local/bin/tldr (the binary IS tealdeer; the install path
# is the conventional name). Post-install hook primes the cache so `tldr fd`
# works offline on first invocation.
TEALDEER_VERSION=1.8.1
TEALDEER_URL_amd64_gnu="https://github.com/tealdeer-rs/tealdeer/releases/download/v${TEALDEER_VERSION}/tealdeer-linux-x86_64-musl"
TEALDEER_URL_amd64_musl="$TEALDEER_URL_amd64_gnu"
TEALDEER_URL_arm64_gnu="https://github.com/tealdeer-rs/tealdeer/releases/download/v${TEALDEER_VERSION}/tealdeer-linux-aarch64-musl"
TEALDEER_URL_arm64_musl="$TEALDEER_URL_arm64_gnu"
TEALDEER_ARCHIVE=none
TEALDEER_BIN_IN_ARCHIVE=.
TEALDEER_INSTALL_AS=/usr/local/bin/tldr
TEALDEER_SMOKE="tldr --version"
TEALDEER_POSTINSTALL_HOOK=tealdeer_postinstall

# REGISTRY_TOOLS is the canonical list of tools handled by the engine. install.sh
# sources this file, reads this variable, and hands it to registry_fetch_all +
# registry_install_all. Adding a new tool means: (1) append a block above,
# (2) add the lowercase name to this list, (3) delete the now-obsolete
# lib/tools/<tool>.sh if any.
REGISTRY_TOOLS="cheat eza gh gopass lazygit lsd micro neovim qsv starship tealdeer zoxide"
