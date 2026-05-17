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

# ----- helix ----- editor; glibc-only tarball; ships a runtime/ dir its
# binary needs at runtime. Post-install hook copies runtime/ into
# /usr/local/share/helix/ via REGISTRY_TMP_DIR.
HELIX_VERSION=25.07.1
HELIX_URL_amd64_gnu="https://github.com/helix-editor/helix/releases/download/${HELIX_VERSION}/helix-${HELIX_VERSION}-x86_64-linux.tar.xz"
HELIX_URL_amd64_musl=""
HELIX_URL_arm64_gnu="https://github.com/helix-editor/helix/releases/download/${HELIX_VERSION}/helix-${HELIX_VERSION}-aarch64-linux.tar.xz"
HELIX_URL_arm64_musl=""
HELIX_ARCHIVE=tar.xz
HELIX_BIN_IN_ARCHIVE_amd64="helix-${HELIX_VERSION}-x86_64-linux/hx"
HELIX_BIN_IN_ARCHIVE_arm64="helix-${HELIX_VERSION}-aarch64-linux/hx"
HELIX_BIN_IN_ARCHIVE="$HELIX_BIN_IN_ARCHIVE_amd64"
HELIX_INSTALL_AS=/usr/local/bin/hx
HELIX_SMOKE="hx --version"
HELIX_POSTINSTALL_HOOK=helix_postinstall
HELIX_FALLBACK_PKG=helix

# ----- fzf ----- Go binary tarball; shell-integration scripts come from the
# source repo (raw.githubusercontent.com) pinned to the same tag, via hook.
FZF_VERSION=0.72.0
FZF_URL_amd64_gnu="https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz"
FZF_URL_amd64_musl="$FZF_URL_amd64_gnu"
FZF_URL_arm64_gnu="https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_arm64.tar.gz"
FZF_URL_arm64_musl="$FZF_URL_arm64_gnu"
FZF_ARCHIVE=tar.gz
FZF_BIN_IN_ARCHIVE=fzf
FZF_INSTALL_AS=/usr/local/bin/fzf
FZF_SMOKE="fzf --version"
FZF_POSTINSTALL_HOOK=fzf_postinstall

# ----- ripgrep ----- Rust tarball; gnu+musl for both arches.
RIPGREP_VERSION=15.1.0
RIPGREP_URL_amd64_gnu="https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl.tar.gz"
RIPGREP_URL_amd64_musl="$RIPGREP_URL_amd64_gnu"
RIPGREP_URL_arm64_gnu="https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-aarch64-unknown-linux-gnu.tar.gz"
RIPGREP_URL_arm64_musl="$RIPGREP_URL_arm64_gnu"
RIPGREP_ARCHIVE=tar.gz
RIPGREP_BIN_IN_ARCHIVE_amd64="ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl/rg"
RIPGREP_BIN_IN_ARCHIVE_arm64="ripgrep-${RIPGREP_VERSION}-aarch64-unknown-linux-gnu/rg"
RIPGREP_BIN_IN_ARCHIVE="$RIPGREP_BIN_IN_ARCHIVE_amd64"
RIPGREP_INSTALL_AS=/usr/local/bin/rg
RIPGREP_SMOKE="rg --version"
RIPGREP_FALLBACK_PKG=ripgrep

# ----- bat ----- Rust tarball; gnu+musl for amd64, gnu only for arm64.
BAT_VERSION=0.26.1
BAT_URL_amd64_gnu="https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
BAT_URL_amd64_musl="https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz"
BAT_URL_arm64_gnu="https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-aarch64-unknown-linux-gnu.tar.gz"
BAT_URL_arm64_musl="$BAT_URL_arm64_gnu"
BAT_ARCHIVE=tar.gz
BAT_BIN_IN_ARCHIVE_amd64_gnu="bat-v${BAT_VERSION}-x86_64-unknown-linux-gnu/bat"
BAT_BIN_IN_ARCHIVE_amd64_musl="bat-v${BAT_VERSION}-x86_64-unknown-linux-musl/bat"
BAT_BIN_IN_ARCHIVE_arm64="bat-v${BAT_VERSION}-aarch64-unknown-linux-gnu/bat"
BAT_BIN_IN_ARCHIVE="$BAT_BIN_IN_ARCHIVE_amd64_gnu"
BAT_INSTALL_AS=/usr/local/bin/bat
BAT_SMOKE="bat --version"

# ----- fd ----- Rust tarball; gnu+musl for amd64, gnu only for arm64.
FD_VERSION=10.4.2
FD_URL_amd64_gnu="https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
FD_URL_amd64_musl="https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz"
FD_URL_arm64_gnu="https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-aarch64-unknown-linux-gnu.tar.gz"
FD_URL_arm64_musl="$FD_URL_arm64_gnu"
FD_ARCHIVE=tar.gz
FD_BIN_IN_ARCHIVE_amd64_gnu="fd-v${FD_VERSION}-x86_64-unknown-linux-gnu/fd"
FD_BIN_IN_ARCHIVE_amd64_musl="fd-v${FD_VERSION}-x86_64-unknown-linux-musl/fd"
FD_BIN_IN_ARCHIVE_arm64="fd-v${FD_VERSION}-aarch64-unknown-linux-gnu/fd"
FD_BIN_IN_ARCHIVE="$FD_BIN_IN_ARCHIVE_amd64_gnu"
FD_INSTALL_AS=/usr/local/bin/fd
FD_SMOKE="fd --version"
FD_FALLBACK_PKG=fd-find

# ----- jq ----- raw single-file binaries (no archive).
JQ_VERSION=1.8.1
JQ_URL_amd64_gnu="https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-amd64"
JQ_URL_amd64_musl="$JQ_URL_amd64_gnu"
JQ_URL_arm64_gnu="https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-arm64"
JQ_URL_arm64_musl="$JQ_URL_arm64_gnu"
JQ_ARCHIVE=none
JQ_BIN_IN_ARCHIVE=.
JQ_INSTALL_AS=/usr/local/bin/jq
JQ_SMOKE="jq --version"

# ----- delta (git-delta) ----- Rust tarball; gnu+musl for amd64.
DELTA_VERSION=0.19.2
DELTA_URL_amd64_gnu="https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
DELTA_URL_amd64_musl="https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl.tar.gz"
DELTA_URL_arm64_gnu="https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-aarch64-unknown-linux-gnu.tar.gz"
DELTA_URL_arm64_musl="$DELTA_URL_arm64_gnu"
DELTA_ARCHIVE=tar.gz
DELTA_BIN_IN_ARCHIVE_amd64_gnu="delta-${DELTA_VERSION}-x86_64-unknown-linux-gnu/delta"
DELTA_BIN_IN_ARCHIVE_amd64_musl="delta-${DELTA_VERSION}-x86_64-unknown-linux-musl/delta"
DELTA_BIN_IN_ARCHIVE_arm64="delta-${DELTA_VERSION}-aarch64-unknown-linux-gnu/delta"
DELTA_BIN_IN_ARCHIVE="$DELTA_BIN_IN_ARCHIVE_amd64_gnu"
DELTA_INSTALL_AS=/usr/local/bin/delta
DELTA_SMOKE="delta --version"
DELTA_FALLBACK_PKG=git-delta

# ----- lnav ----- musl-only zip; works on both glibc and musl.
LNAV_VERSION=0.14.0
LNAV_URL_amd64_gnu="https://github.com/tstack/lnav/releases/download/v${LNAV_VERSION}/lnav-${LNAV_VERSION}-linux-musl-x86_64.zip"
LNAV_URL_amd64_musl="$LNAV_URL_amd64_gnu"
LNAV_URL_arm64_gnu="https://github.com/tstack/lnav/releases/download/v${LNAV_VERSION}/lnav-${LNAV_VERSION}-linux-musl-arm64.zip"
LNAV_URL_arm64_musl="$LNAV_URL_arm64_gnu"
LNAV_ARCHIVE=zip
LNAV_BIN_IN_ARCHIVE="lnav-${LNAV_VERSION}/lnav"
LNAV_INSTALL_AS=/usr/local/bin/lnav
LNAV_SMOKE="lnav --version"

# ----- gron ----- Go binary (static); flat tarball.
GRON_VERSION=0.7.1
GRON_URL_amd64_gnu="https://github.com/tomnomnom/gron/releases/download/v${GRON_VERSION}/gron-linux-amd64-${GRON_VERSION}.tgz"
GRON_URL_amd64_musl="$GRON_URL_amd64_gnu"
GRON_URL_arm64_gnu="https://github.com/tomnomnom/gron/releases/download/v${GRON_VERSION}/gron-linux-arm64-${GRON_VERSION}.tgz"
GRON_URL_arm64_musl="$GRON_URL_arm64_gnu"
GRON_ARCHIVE=tar.gz
GRON_BIN_IN_ARCHIVE=gron
GRON_INSTALL_AS=/usr/local/bin/gron
GRON_SMOKE="gron --version"
# gron's --version output is `gron version dev` (Go build embeds "dev"
# instead of the tag). Skip version-string verification; smoke alone is
# what we can check.
GRON_VERSION_PATTERN=skip

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
REGISTRY_TOOLS="bat cheat delta eza fd fzf gh gopass gron helix jq lazygit lnav lsd micro neovim qsv ripgrep starship tealdeer zoxide"
