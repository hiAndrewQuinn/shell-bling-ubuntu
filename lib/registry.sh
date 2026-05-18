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
CHEAT_SHA256_amd64_gnu=8c8405574d51d63ee89594bfed241f478d507d96af78e5c370dcbe65633d7b34
CHEAT_SHA512_amd64_gnu=b6172f0e76257583e2c3b1f46c1be6a155294b3b7b2be3035debd656665f41f1d21a0e8d68bf3fddfebe722510541e3b7c01c4075298e5ff34459d88e0543d4f
CHEAT_URL_amd64_musl="$CHEAT_URL_amd64_gnu"
CHEAT_SHA256_amd64_musl=8c8405574d51d63ee89594bfed241f478d507d96af78e5c370dcbe65633d7b34
CHEAT_SHA512_amd64_musl=b6172f0e76257583e2c3b1f46c1be6a155294b3b7b2be3035debd656665f41f1d21a0e8d68bf3fddfebe722510541e3b7c01c4075298e5ff34459d88e0543d4f
CHEAT_URL_arm64_gnu="https://github.com/cheat/cheat/releases/download/${CHEAT_VERSION}/cheat-linux-arm64.gz"
CHEAT_SHA256_arm64_gnu=78fd70fedd7c2cd297af827c29c495c8f6d2b9a880739450ac13e18eefa2f17b
CHEAT_SHA512_arm64_gnu=0f492af6307394388edee38a4fca7568175dd916095db1c9cc3773750427a5439659a5f35583e688fb662731ffbc5de29e60c911dc642e21b8a561569f403928
CHEAT_URL_arm64_musl="$CHEAT_URL_arm64_gnu"
CHEAT_SHA256_arm64_musl=78fd70fedd7c2cd297af827c29c495c8f6d2b9a880739450ac13e18eefa2f17b
CHEAT_SHA512_arm64_musl=0f492af6307394388edee38a4fca7568175dd916095db1c9cc3773750427a5439659a5f35583e688fb662731ffbc5de29e60c911dc642e21b8a561569f403928
CHEAT_ARCHIVE=gz
CHEAT_BIN_IN_ARCHIVE=.
CHEAT_INSTALL_AS=/usr/local/bin/cheat
CHEAT_SMOKE="cheat --version"

# ----- eza ----- gnu and musl tarballs for both arches.
# Modern Rust gnu binaries don't work on glibc < ~2.27; push CentOS 7
# (2.17) and Amazon Linux 2 (2.26) to the musl variant.
EZA_GLIBC_MIN=2.28
EZA_VERSION=0.23.4
EZA_URL_amd64_gnu="https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz"
EZA_SHA256_amd64_gnu=0c38665440226cd8bef5d1d4f3bc6ff77c927fb0d68b752739105db7ab5b358d
EZA_SHA512_amd64_gnu=116f10e268d493a936d411a5e3b2658e21cb31124946015f9e5884dd7f23498abd2edb3da285effb128afa23fd9d19e0d424461a3c1c35bd3c7ad6aa72a6615e
EZA_URL_amd64_musl="https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_x86_64-unknown-linux-musl.tar.gz"
EZA_SHA256_amd64_musl=d231bb3ee33b08c76279b5888845dceb7034d055c42bb9be46dbe0dae39394df
EZA_SHA512_amd64_musl=e750e4d320173f759b82d64a1c7c3bdb3872dfedb4d083b22f8b20928a8cc81221f37dba052cde78de28f1cbb69c00d06e508bf4129193fd4ed0ddc83adea0f6
EZA_URL_arm64_gnu="https://github.com/eza-community/eza/releases/download/v${EZA_VERSION}/eza_aarch64-unknown-linux-gnu.tar.gz"
EZA_SHA256_arm64_gnu=366e8430225f9955c3dc659b452150c169894833ccfef455e01765e265a3edda
EZA_SHA512_arm64_gnu=ebbad7ada865c707357dadc3b0fcdd7963be8491498098112e9eed1957cf14654318f90fe7229a8a88044b8c26730dd28981132501803656509bc51e8263da4c
EZA_URL_arm64_musl="$EZA_URL_arm64_gnu"
EZA_SHA256_arm64_musl=366e8430225f9955c3dc659b452150c169894833ccfef455e01765e265a3edda
EZA_SHA512_arm64_musl=ebbad7ada865c707357dadc3b0fcdd7963be8491498098112e9eed1957cf14654318f90fe7229a8a88044b8c26730dd28981132501803656509bc51e8263da4c
EZA_ARCHIVE=tar.gz
EZA_BIN_IN_ARCHIVE=./eza
EZA_INSTALL_AS=/usr/local/bin/eza
EZA_SMOKE="eza --version"

# ----- gh ----- official tarballs alongside the deb/rpm assets.
GH_VERSION=2.92.0
GH_URL_amd64_gnu="https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz"
GH_SHA256_amd64_gnu=b57848131bdf0c229cd35e1f2a51aa718199858b2e728410b37e89a428943ec4
GH_SHA512_amd64_gnu=7f5e6379e0092c883d5666a57a63106db33e074a5e62693463172e7bc15c8be56f7b7f5a45c18261a9d26c3cf70a2f2128708b5354d0fbc250b1331bf3d9f460
GH_URL_amd64_musl="$GH_URL_amd64_gnu"
GH_SHA256_amd64_musl=b57848131bdf0c229cd35e1f2a51aa718199858b2e728410b37e89a428943ec4
GH_SHA512_amd64_musl=7f5e6379e0092c883d5666a57a63106db33e074a5e62693463172e7bc15c8be56f7b7f5a45c18261a9d26c3cf70a2f2128708b5354d0fbc250b1331bf3d9f460
GH_URL_arm64_gnu="https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_arm64.tar.gz"
GH_SHA256_arm64_gnu=c2248526dd0160c08d3fccca2332c3c1a07c15a78b23978e77735f1b5a18cfee
GH_SHA512_arm64_gnu=73dd731d8b539d03b5cc70679886adce2b4aa1879479c8e780a369ec444b17e78882148493bc548e9ace4bcef59cd8c2e5fc557604e464f4bd818881662414c9
GH_URL_arm64_musl="$GH_URL_arm64_gnu"
GH_SHA256_arm64_musl=c2248526dd0160c08d3fccca2332c3c1a07c15a78b23978e77735f1b5a18cfee
GH_SHA512_arm64_musl=73dd731d8b539d03b5cc70679886adce2b4aa1879479c8e780a369ec444b17e78882148493bc548e9ace4bcef59cd8c2e5fc557604e464f4bd818881662414c9
GH_ARCHIVE=tar.gz
GH_BIN_IN_ARCHIVE="gh_${GH_VERSION}_linux_amd64/bin/gh"
# Per-arch path-inside-tarball differs; override below.
GH_BIN_IN_ARCHIVE_amd64="gh_${GH_VERSION}_linux_amd64/bin/gh"
GH_BIN_IN_ARCHIVE_arm64="gh_${GH_VERSION}_linux_arm64/bin/gh"
GH_INSTALL_AS=/usr/local/bin/gh
GH_SMOKE="gh --version"
GH_FALLBACK_PKG=github-cli
GH_SIG_TYPE=shasums-plain
GH_SIG_URL="https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_checksums.txt"

# ----- gopass ----- Go binary; gnu+musl tarballs published per arch.
GOPASS_VERSION=1.16.1
GOPASS_URL_amd64_gnu="https://github.com/gopasspw/gopass/releases/download/v${GOPASS_VERSION}/gopass-${GOPASS_VERSION}-linux-amd64.tar.gz"
GOPASS_SHA256_amd64_gnu=be77309ba4491cedfb847155380fc04c3f356231d368721ee3c69b77ab0c0eb7
GOPASS_SHA512_amd64_gnu=348679079e8d53f43490b63c57d1fa83a872ed1535855632c430fa9084473539f2100df062301e4644086c6b862a7539e2fab767555396eb019532da094f1686
GOPASS_URL_amd64_musl="$GOPASS_URL_amd64_gnu"
GOPASS_SHA256_amd64_musl=be77309ba4491cedfb847155380fc04c3f356231d368721ee3c69b77ab0c0eb7
GOPASS_SHA512_amd64_musl=348679079e8d53f43490b63c57d1fa83a872ed1535855632c430fa9084473539f2100df062301e4644086c6b862a7539e2fab767555396eb019532da094f1686
GOPASS_URL_arm64_gnu="https://github.com/gopasspw/gopass/releases/download/v${GOPASS_VERSION}/gopass-${GOPASS_VERSION}-linux-arm64.tar.gz"
GOPASS_SHA256_arm64_gnu=99d66e7cd937f47bf858c238c2cb912a36beb7312b6c52fa65f8a29278dd800d
GOPASS_SHA512_arm64_gnu=a67efc293dba395c7334beee997329d2ec778f1451a3b9045697d2e19a80b5b1bcf828a9aeb8d6432aeaceeffe8d55e9b6e276a1ad2f68c737109e95ac25f00e
GOPASS_URL_arm64_musl="$GOPASS_URL_arm64_gnu"
GOPASS_SHA256_arm64_musl=99d66e7cd937f47bf858c238c2cb912a36beb7312b6c52fa65f8a29278dd800d
GOPASS_SHA512_arm64_musl=a67efc293dba395c7334beee997329d2ec778f1451a3b9045697d2e19a80b5b1bcf828a9aeb8d6432aeaceeffe8d55e9b6e276a1ad2f68c737109e95ac25f00e
GOPASS_ARCHIVE=tar.gz
GOPASS_BIN_IN_ARCHIVE=gopass
GOPASS_INSTALL_AS=/usr/local/bin/gopass
GOPASS_SYMLINKS="pass" # /usr/local/bin/pass -> gopass (compat with existing pass muscle memory)
GOPASS_SMOKE="gopass --version"
GOPASS_SIG_TYPE=shasums-plain
GOPASS_SIG_URL="https://github.com/gopasspw/gopass/releases/download/v${GOPASS_VERSION}/gopass_${GOPASS_VERSION}_SHA256SUMS"

# ----- lazygit ----- Go binary; one tarball runs on glibc and musl.
LAZYGIT_VERSION=0.61.1
LAZYGIT_URL_amd64_gnu="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_x86_64.tar.gz"
LAZYGIT_SHA256_amd64_gnu=1b91e660700f2332696726b635202576b543e2bc49b639830dccd26bc5160d5d
LAZYGIT_SHA512_amd64_gnu=3ab98483563945e649d3621bbecae1413c84b03cb4b07273a66b7efe278739d47534a339ae1040992968ecc071b0f4ac54db080b10edc3901bcb6deeb27ae58d
LAZYGIT_URL_amd64_musl="$LAZYGIT_URL_amd64_gnu"
LAZYGIT_SHA256_amd64_musl=1b91e660700f2332696726b635202576b543e2bc49b639830dccd26bc5160d5d
LAZYGIT_SHA512_amd64_musl=3ab98483563945e649d3621bbecae1413c84b03cb4b07273a66b7efe278739d47534a339ae1040992968ecc071b0f4ac54db080b10edc3901bcb6deeb27ae58d
LAZYGIT_URL_arm64_gnu="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_arm64.tar.gz"
LAZYGIT_SHA256_arm64_gnu=20b1abb2bee5dfd46173b9047353eb678bc51a23839e821958d0b1863ab1655e
LAZYGIT_SHA512_arm64_gnu=7155abb0779e6935a2a731219645ba01c2ec245d96ec2232a90a8fc2f68d2983b2c892c509ae74b2f5dbc90a82d29e2ba49631e159e0d4e4cf668f3667c74ffe
LAZYGIT_URL_arm64_musl="$LAZYGIT_URL_arm64_gnu"
LAZYGIT_SHA256_arm64_musl=20b1abb2bee5dfd46173b9047353eb678bc51a23839e821958d0b1863ab1655e
LAZYGIT_SHA512_arm64_musl=7155abb0779e6935a2a731219645ba01c2ec245d96ec2232a90a8fc2f68d2983b2c892c509ae74b2f5dbc90a82d29e2ba49631e159e0d4e4cf668f3667c74ffe
LAZYGIT_ARCHIVE=tar.gz
LAZYGIT_BIN_IN_ARCHIVE=lazygit
LAZYGIT_INSTALL_AS=/usr/local/bin/lazygit
LAZYGIT_SMOKE="lazygit --version"
LAZYGIT_SIG_TYPE=shasums-plain
LAZYGIT_SIG_URL="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/checksums.txt"

# ----- lsd ----- gnu+musl tarballs, both arches.
# See EZA_GLIBC_MIN comment — same heuristic for the legacy-glibc cliff.
LSD_GLIBC_MIN=2.28
LSD_VERSION=1.2.0
LSD_URL_amd64_gnu="https://github.com/lsd-rs/lsd/releases/download/v${LSD_VERSION}/lsd-v${LSD_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
LSD_SHA256_amd64_gnu=57d3b5859254adcfb8374ce98159cca97a14959997d2ae1176d2cff59556d829
LSD_SHA512_amd64_gnu=223f0ce29c2ae38606e8a3b31b26dbe51e8bec12066a758732f4af753046ddda3f232b863224a3d32e5141eba85bf8a199da2f69e8efcd4a48b4638f93ec4271
LSD_URL_amd64_musl="https://github.com/lsd-rs/lsd/releases/download/v${LSD_VERSION}/lsd-v${LSD_VERSION}-x86_64-unknown-linux-musl.tar.gz"
LSD_SHA256_amd64_musl=77849da1210336534258551a581401ba19ae6b8d7b66a2a1feff148ad41e3814
LSD_SHA512_amd64_musl=8f45d30eb781d861d143d1b7ea150e5ecaa60559f27c1ab172eb483993dda3aa696097f383e1a50fed1deb4643f703c594e46b454d071360686157a0e716fd40
LSD_URL_arm64_gnu="https://github.com/lsd-rs/lsd/releases/download/v${LSD_VERSION}/lsd-v${LSD_VERSION}-aarch64-unknown-linux-gnu.tar.gz"
LSD_SHA256_arm64_gnu=48c069cf73a8ed0851f366afeac86e3a9b7db416133f45d033d31d123f819f26
LSD_SHA512_arm64_gnu=2ee55a3e8dc64c1880bddfdce04c27ef1b04bc9c349477e1aff23a786938ed36e15c45444755d9f26243aea8fbfc442aedad235a868512b726f1fdcf5f6a16bc
LSD_URL_arm64_musl="$LSD_URL_arm64_gnu"
LSD_SHA256_arm64_musl=48c069cf73a8ed0851f366afeac86e3a9b7db416133f45d033d31d123f819f26
LSD_SHA512_arm64_musl=2ee55a3e8dc64c1880bddfdce04c27ef1b04bc9c349477e1aff23a786938ed36e15c45444755d9f26243aea8fbfc442aedad235a868512b726f1fdcf5f6a16bc
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
MICRO_SHA256_amd64_gnu=dfa1b6ae53e4e0b063b54224fd2b6b0a3c3159ea09d042a3a8f5cd001844d44c
MICRO_SHA512_amd64_gnu=00a6f6ebdfe26dc0f7eb93d0f2f391fab64da7b480456c78a95ee531ac72b16c8ef9e6910dec291c9c93ecca72f5744cfc4240e7fa3065a3e1410ecf3386babb
MICRO_URL_amd64_musl="https://github.com/zyedidia/micro/releases/download/v${MICRO_VERSION}/micro-${MICRO_VERSION}-linux64-static.tar.gz"
MICRO_SHA256_amd64_musl=267d238eac1e26ed053d13d4d48bd421b87f9eb538b604f0b2f74a85598b6cc2
MICRO_SHA512_amd64_musl=6a6329024333f2cb202c38a92818c2509da76b8f7d5f143f92bc5669da3ecd1f82921190e3a0d34f1a108f7e90accf3a3fd82e321b548afdcb5385d4d85504dc
MICRO_URL_arm64_gnu="https://github.com/zyedidia/micro/releases/download/v${MICRO_VERSION}/micro-${MICRO_VERSION}-linux-arm64.tar.gz"
MICRO_SHA256_arm64_gnu=5ca127857bf5500be3879f1a70b27556e737a49da04a1be5334de9e8e8781ad9
MICRO_SHA512_arm64_gnu=629374c82f67ff9c2ab30043d0523eb5c7acb7c39d39ff347710c095abc397a6a4a431b1b3e8eff48a8efd64eb90fac0eaffe8e3555d3133d2c16184f1c92b0d
MICRO_URL_arm64_musl="$MICRO_URL_arm64_gnu"
MICRO_SHA256_arm64_musl=5ca127857bf5500be3879f1a70b27556e737a49da04a1be5334de9e8e8781ad9
MICRO_SHA512_arm64_musl=629374c82f67ff9c2ab30043d0523eb5c7acb7c39d39ff347710c095abc397a6a4a431b1b3e8eff48a8efd64eb90fac0eaffe8e3555d3133d2c16184f1c92b0d
MICRO_ARCHIVE=tar.gz
MICRO_BIN_IN_ARCHIVE="micro-${MICRO_VERSION}/micro"
MICRO_INSTALL_AS=/usr/local/bin/micro
MICRO_SMOKE="micro -version"

# ----- neovim ----- glibc-only tarballs (Alpine falls through to apk).
# nvim 0.12.x's upstream tarball is linked against glibc 2.34+. On older
# distros (Debian 11/Ubuntu 20.04, both ship glibc 2.31) the engine
# fallback path matches qsv's: no -musl variant pinned → URL resolves to
# empty → pkg_install fallback installs whatever the distro carries
# (e.g. nvim 0.4.x from bullseye). Older nvim is still nvim; lazyvim
# bootstrap may need adjustments but the editor works.
NEOVIM_GLIBC_MIN=2.34
NEOVIM_VERSION=0.12.2
NEOVIM_URL_amd64_gnu="https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-x86_64.tar.gz"
NEOVIM_SHA256_amd64_gnu=31cf85945cb600d96cdf69f88bc68bec814acbff50863c5546adef3a1bcef260
NEOVIM_SHA512_amd64_gnu=7d10e9b0e9cd8ab9d7be6893011b07f72520ee07401fc6a1c63014ea8312bcae210158eed766c8a30a72bc5bcf5779175462d35b7cd2f004827c6f25d66ccd48
NEOVIM_URL_amd64_musl="" # no musl build — engine falls through
NEOVIM_URL_arm64_gnu="https://github.com/neovim/neovim/releases/download/v${NEOVIM_VERSION}/nvim-linux-arm64.tar.gz"
NEOVIM_SHA256_arm64_gnu=f697d4e4582b6e4b5c3c26e76e06ce26efa08ba1768e03fd2733fcc422bb0490
NEOVIM_SHA512_arm64_gnu=dcf95fcc325eedbf191de4d965148314517ade7e4e17c8f389c48d9ae2a678e3fcb322f922bb7613ae39f4cd9c401d54d0b39c4b37894b282d0933b76eedf73c
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
# qsv's prebuilt -gnu binaries need glibc >= 2.39 (the binary segfaults on
# 2.38; surfaced on openSUSE Leap 15.6). Bumped from 2.38 to 2.39 to push
# Leap-and-older onto the musl variant which works on any glibc.
QSV_GLIBC_MIN=2.39
QSV_VERSION=20.0.0
QSV_URL_amd64_gnu="https://github.com/dathere/qsv/releases/download/${QSV_VERSION}/qsv-${QSV_VERSION}-x86_64-unknown-linux-gnu.zip"
QSV_SHA256_amd64_gnu=e22aa273e9b2a5674e1be3974acf58eea5364986a54e7b22c93f09e650b694e3
QSV_SHA512_amd64_gnu=0a567c83d16bfc4d200216c2b68d19930cfce79f53e72434c2356dd05bf79f3e6212c9e2abf565fdfab15ec07f21c4646a060960f4e058fc6fa3bafe029b3d5d
QSV_URL_amd64_musl="https://github.com/dathere/qsv/releases/download/${QSV_VERSION}/qsv-${QSV_VERSION}-x86_64-unknown-linux-musl.zip"
QSV_SHA256_amd64_musl=c8107bd6a134ccbe466b925497f6e6a95c7741fb973a28999b90d7f50873afd6
QSV_SHA512_amd64_musl=d35a29d72d1911b246f7dd26a5af7566c3f6e162f109143284a279c1f7dddec982b8fa919d3fbcbba0760cc93b7d690218c33fe0af12d868250c62ee15577edd
QSV_URL_arm64_gnu="https://github.com/dathere/qsv/releases/download/${QSV_VERSION}/qsv-${QSV_VERSION}-aarch64-unknown-linux-gnu.zip"
QSV_SHA256_arm64_gnu=7acfa5d9a3f01ccd48e3049e6ec6393ddb8878f575b4d0ecf205de1ddfa8c7c6
QSV_SHA512_arm64_gnu=e31002a5c62f85882d581afce94fb32e75f6b51ec759eac5d644ea451d1bae3aec9e9d9fb3c2d0d00501a40e53dbcd6b62dd11d69ec2b76242cfa6de517718eb
QSV_URL_arm64_musl="" # not shipped upstream
QSV_ARCHIVE=zip
QSV_BIN_IN_ARCHIVE=qsv
QSV_EXTRA_BINS="qsvlite qsvdp"
QSV_INSTALL_AS=/usr/local/bin/qsv
QSV_SMOKE="qsv --version"

# ----- starship ----- arm64 ships musl-only; amd64 has both. Musl works on glibc.
# See EZA_GLIBC_MIN comment — same heuristic for the legacy-glibc cliff.
STARSHIP_GLIBC_MIN=2.28
STARSHIP_VERSION=1.25.1
STARSHIP_URL_amd64_gnu="https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-x86_64-unknown-linux-gnu.tar.gz"
STARSHIP_SHA256_amd64_gnu=4488c11ca632327d1f1f16fb2f102c0646094c35479cd5435991385da43c61ac
STARSHIP_SHA512_amd64_gnu=28ce423e0cff8a7e687071ba06e74f2a7e66093ad70c4a17bd604ea2fa4034af9777fd584c28f2b803923a109250198e0c9602d3c4ecac38066221ec1f1091ff
STARSHIP_URL_amd64_musl="https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-x86_64-unknown-linux-musl.tar.gz"
STARSHIP_SHA256_amd64_musl=c6ddd3ecb9c0071a2ad38d98cee748160066b7c4f197421268058f4a5d6f8504
STARSHIP_SHA512_amd64_musl=982f402b995864389ad9418a0253990f8cfa731f3cc58563139879d46dbb85401375469fd40643ac21fb35d4e115d1b00e2bd237eca7ef8d64dee97138024e1d
STARSHIP_URL_arm64_gnu="https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-aarch64-unknown-linux-musl.tar.gz"
STARSHIP_SHA256_arm64_gnu=01517aab398959ea9ea73bdb4f032ea4dbb51dff5c8e5eb05b4a1b9b7ab872b8
STARSHIP_SHA512_arm64_gnu=12de4194e86d7143cfca212cf767df13a0acae00d051f2f34db10c02b242c53cfeeae24e078a3fe53d6f9ec7f2386b2934796c9930963fb54ed753c8fa698bd4
STARSHIP_URL_arm64_musl="$STARSHIP_URL_arm64_gnu"
STARSHIP_SHA256_arm64_musl=01517aab398959ea9ea73bdb4f032ea4dbb51dff5c8e5eb05b4a1b9b7ab872b8
STARSHIP_SHA512_arm64_musl=12de4194e86d7143cfca212cf767df13a0acae00d051f2f34db10c02b242c53cfeeae24e078a3fe53d6f9ec7f2386b2934796c9930963fb54ed753c8fa698bd4
STARSHIP_ARCHIVE=tar.gz
STARSHIP_BIN_IN_ARCHIVE=starship
STARSHIP_INSTALL_AS=/usr/local/bin/starship
STARSHIP_SMOKE="starship --version"

# ----- zoxide ----- musl-only Rust release; runs on glibc fine.
ZOXIDE_VERSION=0.9.9
ZOXIDE_URL_amd64_gnu="https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-x86_64-unknown-linux-musl.tar.gz"
ZOXIDE_SHA256_amd64_gnu=4ff057d3c4d957946937274c2b8be7af2a9bbae7f90a1b5e9baaa7cb65a20caa
ZOXIDE_SHA512_amd64_gnu=f1a310b8b3e243426957fcbcb4d7b360a810a6ff12efa6c53d07cbe9435d65cbdcb6ab5f57123a60921822bb12023926ceade887ce1fd66eaaa45feed5e31ce7
ZOXIDE_URL_amd64_musl="$ZOXIDE_URL_amd64_gnu"
ZOXIDE_SHA256_amd64_musl=4ff057d3c4d957946937274c2b8be7af2a9bbae7f90a1b5e9baaa7cb65a20caa
ZOXIDE_SHA512_amd64_musl=f1a310b8b3e243426957fcbcb4d7b360a810a6ff12efa6c53d07cbe9435d65cbdcb6ab5f57123a60921822bb12023926ceade887ce1fd66eaaa45feed5e31ce7
ZOXIDE_URL_arm64_gnu="https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-aarch64-unknown-linux-musl.tar.gz"
ZOXIDE_SHA256_arm64_gnu=96e6ea2e47a71db42cb7ad5a36e9209c8cb3708f8ae00f6945573d0d93315cb0
ZOXIDE_SHA512_arm64_gnu=6643bbb7d714d662a3b8405d841f1a3dc64d38b3ed4f5a7f941b9dcb7ad7973aea4adb473e86c5908a94f10df70df924cc18735438a3e2c0d030a2329594c189
ZOXIDE_URL_arm64_musl="$ZOXIDE_URL_arm64_gnu"
ZOXIDE_SHA256_arm64_musl=96e6ea2e47a71db42cb7ad5a36e9209c8cb3708f8ae00f6945573d0d93315cb0
ZOXIDE_SHA512_arm64_musl=6643bbb7d714d662a3b8405d841f1a3dc64d38b3ed4f5a7f941b9dcb7ad7973aea4adb473e86c5908a94f10df70df924cc18735438a3e2c0d030a2329594c189
ZOXIDE_ARCHIVE=tar.gz
ZOXIDE_BIN_IN_ARCHIVE=zoxide
ZOXIDE_INSTALL_AS=/usr/local/bin/zoxide
ZOXIDE_SMOKE="zoxide --version"

# ----- fish ----- fish 4.x ships a "standalone" tarball with a single
# statically-linked binary. One URL per arch; works on glibc and musl.
# Post-install hook registers the binary path in /etc/shells so chsh works.
FISH_VERSION=4.7.1
FISH_URL_amd64_gnu="https://github.com/fish-shell/fish-shell/releases/download/${FISH_VERSION}/fish-${FISH_VERSION}-linux-x86_64.tar.xz"
FISH_SHA256_amd64_gnu=345388add316b94a847b08cef01f1b46e85b98215328271ee22a21555a3204df
FISH_SHA512_amd64_gnu=989ec228b1a9e9a87beaad5ce9de251927d3b87acd58882487d31a868dc5114fb106cc61fa68ee0e8bb3b62871088f28641b037f5f41c47c97139a1cf50c5fb9
FISH_URL_amd64_musl="$FISH_URL_amd64_gnu"
FISH_SHA256_amd64_musl=345388add316b94a847b08cef01f1b46e85b98215328271ee22a21555a3204df
FISH_SHA512_amd64_musl=989ec228b1a9e9a87beaad5ce9de251927d3b87acd58882487d31a868dc5114fb106cc61fa68ee0e8bb3b62871088f28641b037f5f41c47c97139a1cf50c5fb9
FISH_URL_arm64_gnu="https://github.com/fish-shell/fish-shell/releases/download/${FISH_VERSION}/fish-${FISH_VERSION}-linux-aarch64.tar.xz"
FISH_SHA256_arm64_gnu=72957265b8629fbb3cdb215260c302f6154403dbaf35d38103aac6af689fb7f6
FISH_SHA512_arm64_gnu=ef0838609e46a74a2d2139ba2c345b8aa485e0e2ab12742bcb28884412f8a57d7e19ad62e02c6e7ded9d98a2dd604b9b87c0702552225812df04d6b57d652513
FISH_URL_arm64_musl="$FISH_URL_arm64_gnu"
FISH_SHA256_arm64_musl=72957265b8629fbb3cdb215260c302f6154403dbaf35d38103aac6af689fb7f6
FISH_SHA512_arm64_musl=ef0838609e46a74a2d2139ba2c345b8aa485e0e2ab12742bcb28884412f8a57d7e19ad62e02c6e7ded9d98a2dd604b9b87c0702552225812df04d6b57d652513
FISH_ARCHIVE=tar.xz
FISH_BIN_IN_ARCHIVE=fish
FISH_INSTALL_AS=/usr/local/bin/fish
FISH_SMOKE="fish --version"
FISH_POSTINSTALL_HOOK=fish_postinstall
FISH_FALLBACK_PKG=fish

# ----- helix ----- editor; glibc-only tarball; ships a runtime/ dir its
# binary needs at runtime. Post-install hook copies runtime/ into
# /usr/local/share/helix/ via REGISTRY_TMP_DIR.
# Upstream tarball requires glibc 2.34+; older distros fall through to
# pkg_install (e.g. helix from bullseye-backports if enabled, or nothing).
HELIX_GLIBC_MIN=2.34
HELIX_VERSION=25.07.1
HELIX_URL_amd64_gnu="https://github.com/helix-editor/helix/releases/download/${HELIX_VERSION}/helix-${HELIX_VERSION}-x86_64-linux.tar.xz"
HELIX_SHA256_amd64_gnu=3f08e63ecd388fff657ad39722f88bb03dcf326f1f2da2700d99e1dc40ab2e8b
HELIX_SHA512_amd64_gnu=55d4a76bbe30c1782ea83d6a482d9984caa7aec97673ab2dde9f4e533f2b44b0e3cc85ba2ab030c52909ea6682c09f1fab7b7a4a86b63ac8a9d6abf282da110a
HELIX_URL_amd64_musl=""
HELIX_URL_arm64_gnu="https://github.com/helix-editor/helix/releases/download/${HELIX_VERSION}/helix-${HELIX_VERSION}-aarch64-linux.tar.xz"
HELIX_SHA256_arm64_gnu=ce23fa8d395e633e3e54c052012f11965d91d8d5c2bfa659685f50430b4f8175
HELIX_SHA512_arm64_gnu=8d10cec8a5dcc5cfe34bba639b14c1f900e65c0b9e8cb4e8a94d04dff3128ff81bb469495f3cd5669d93fe1e13e3532fa17da706ddcc15f04b587cefa8329653
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
FZF_SHA256_amd64_gnu=0e58e4bd0b3c5d68c56b54c460a6863d0de79633ed18d388575a960ab447b006
FZF_SHA512_amd64_gnu=b329271d72c6d99e021291ca3d48cc74d1b539cbfcf8ec0fc09a83ffbb6c62ed84d8ec22c73fd11adc7f936fc8fd0d98d28078ddebfbe39d7fc501e417406bc3
FZF_URL_amd64_musl="$FZF_URL_amd64_gnu"
FZF_SHA256_amd64_musl=0e58e4bd0b3c5d68c56b54c460a6863d0de79633ed18d388575a960ab447b006
FZF_SHA512_amd64_musl=b329271d72c6d99e021291ca3d48cc74d1b539cbfcf8ec0fc09a83ffbb6c62ed84d8ec22c73fd11adc7f936fc8fd0d98d28078ddebfbe39d7fc501e417406bc3
FZF_URL_arm64_gnu="https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_arm64.tar.gz"
FZF_SHA256_arm64_gnu=a0a5b50730f568c5f08b8dbba1e6e598db253e1856d371290086786b889b996b
FZF_SHA512_arm64_gnu=47bbfb7774ddcccc24c735fdc9b38261ff0ecf55d00471f0408636ba126fa7f1b06e2573fcac53f6c643eeb826c44c0b4bc7714d03549f2f702c7580cd225679
FZF_URL_arm64_musl="$FZF_URL_arm64_gnu"
FZF_SHA256_arm64_musl=a0a5b50730f568c5f08b8dbba1e6e598db253e1856d371290086786b889b996b
FZF_SHA512_arm64_musl=47bbfb7774ddcccc24c735fdc9b38261ff0ecf55d00471f0408636ba126fa7f1b06e2573fcac53f6c643eeb826c44c0b4bc7714d03549f2f702c7580cd225679
FZF_ARCHIVE=tar.gz
FZF_BIN_IN_ARCHIVE=fzf
FZF_INSTALL_AS=/usr/local/bin/fzf
FZF_SMOKE="fzf --version"
FZF_POSTINSTALL_HOOK=fzf_postinstall
FZF_SIG_TYPE=shasums-plain
FZF_SIG_URL="https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf_${FZF_VERSION}_checksums.txt"

# ----- ripgrep ----- Rust tarball; gnu+musl for both arches.
RIPGREP_VERSION=15.1.0
RIPGREP_URL_amd64_gnu="https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl.tar.gz"
RIPGREP_SHA256_amd64_gnu=1c9297be4a084eea7ecaedf93eb03d058d6faae29bbc57ecdaf5063921491599
RIPGREP_SHA512_amd64_gnu=c469081f8eff492379a912a7978435a2929abc05e662b0e53dd2bb066df266cab84bedfc572f7b330403a16b5afcd0957ebdb98c5773e8afc0c1df2a465a9d75
RIPGREP_URL_amd64_musl="$RIPGREP_URL_amd64_gnu"
RIPGREP_SHA256_amd64_musl=1c9297be4a084eea7ecaedf93eb03d058d6faae29bbc57ecdaf5063921491599
RIPGREP_SHA512_amd64_musl=c469081f8eff492379a912a7978435a2929abc05e662b0e53dd2bb066df266cab84bedfc572f7b330403a16b5afcd0957ebdb98c5773e8afc0c1df2a465a9d75
RIPGREP_URL_arm64_gnu="https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-aarch64-unknown-linux-gnu.tar.gz"
RIPGREP_SHA256_arm64_gnu=2b661c6ef508e902f388e9098d9c4c5aca72c87b55922d94abdba830b4dc885e
RIPGREP_SHA512_arm64_gnu=84c6f873f0a05457ca6af128fafb16904c47cea977dc8cf35b3e17e1f2f9b9ec7bed4ff9f4edbb80a2c0bbc7d251daf12d8873979dcb8c236f2037d8577068b3
RIPGREP_URL_arm64_musl="$RIPGREP_URL_arm64_gnu"
RIPGREP_SHA256_arm64_musl=2b661c6ef508e902f388e9098d9c4c5aca72c87b55922d94abdba830b4dc885e
RIPGREP_SHA512_arm64_musl=84c6f873f0a05457ca6af128fafb16904c47cea977dc8cf35b3e17e1f2f9b9ec7bed4ff9f4edbb80a2c0bbc7d251daf12d8873979dcb8c236f2037d8577068b3
RIPGREP_ARCHIVE=tar.gz
RIPGREP_BIN_IN_ARCHIVE_amd64="ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl/rg"
RIPGREP_BIN_IN_ARCHIVE_arm64="ripgrep-${RIPGREP_VERSION}-aarch64-unknown-linux-gnu/rg"
RIPGREP_BIN_IN_ARCHIVE="$RIPGREP_BIN_IN_ARCHIVE_amd64"
RIPGREP_INSTALL_AS=/usr/local/bin/rg
RIPGREP_SMOKE="rg --version"
RIPGREP_FALLBACK_PKG=ripgrep

# ----- bat ----- Rust tarball; gnu+musl for amd64, gnu only for arm64.
# See EZA_GLIBC_MIN comment — same heuristic for the legacy-glibc cliff.
BAT_GLIBC_MIN=2.28
BAT_VERSION=0.26.1
BAT_URL_amd64_gnu="https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
BAT_SHA256_amd64_gnu=726f04c8f576a7fd18b7634f1bbf2f915c43494c1c0f013baa3287edb0d5a2a3
BAT_SHA512_amd64_gnu=fa25942394c361a3dc6d049183e04decc07757aa60406fe7850ec353f944ce296718496f1b0b1d076f4db9ab9703239ab538d787c2fba6bfdef7a3adf845ca9c
BAT_URL_amd64_musl="https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz"
BAT_SHA256_amd64_musl=0dcd8ac79732c0d5b136f11f4ee00e581440e16a44eab5b3105b611bbf2cf191
BAT_SHA512_amd64_musl=3cbefa332545c33fa5fb9e78a783047fca97a893909c25b750501cebaa3194b0fa5206bfb959a509333c745199878c54704ebc6e11a8616911ca524cbe2a3f0b
BAT_URL_arm64_gnu="https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-aarch64-unknown-linux-gnu.tar.gz"
BAT_SHA256_arm64_gnu=422eb73e11c854fddd99f5ca8461c2f1d6e6dce0a2a8c3d5daade5ffcb6564aa
BAT_SHA512_arm64_gnu=fbc805f5f40146af84540d3db481b36c8ff556f423c332e998ddad743cb9fa77b21a623389b11f37eb88e034cca668ded5a790400e5860812ecfed568552bdd5
BAT_URL_arm64_musl="$BAT_URL_arm64_gnu"
BAT_SHA256_arm64_musl=422eb73e11c854fddd99f5ca8461c2f1d6e6dce0a2a8c3d5daade5ffcb6564aa
BAT_SHA512_arm64_musl=fbc805f5f40146af84540d3db481b36c8ff556f423c332e998ddad743cb9fa77b21a623389b11f37eb88e034cca668ded5a790400e5860812ecfed568552bdd5
BAT_ARCHIVE=tar.gz
BAT_BIN_IN_ARCHIVE_amd64_gnu="bat-v${BAT_VERSION}-x86_64-unknown-linux-gnu/bat"
BAT_BIN_IN_ARCHIVE_amd64_musl="bat-v${BAT_VERSION}-x86_64-unknown-linux-musl/bat"
BAT_BIN_IN_ARCHIVE_arm64="bat-v${BAT_VERSION}-aarch64-unknown-linux-gnu/bat"
BAT_BIN_IN_ARCHIVE="$BAT_BIN_IN_ARCHIVE_amd64_gnu"
BAT_INSTALL_AS=/usr/local/bin/bat
BAT_SMOKE="bat --version"

# ----- fd ----- Rust tarball; gnu+musl for amd64, gnu only for arm64.
# See EZA_GLIBC_MIN comment — same heuristic for the legacy-glibc cliff.
FD_GLIBC_MIN=2.28
FD_VERSION=10.4.2
FD_URL_amd64_gnu="https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
FD_SHA256_amd64_gnu=def59805cd14b5651b68990855f426ad087f3b96881296d963910431ba3143c8
FD_SHA512_amd64_gnu=99137cdc42eb40efc29a3266918fbc7971d3bf64906271c2daf5ada70d657a56fd5dd65863275497c54bae38a5eedf4cb163a2787d7a837a2195e8a6a9498ab1
FD_URL_amd64_musl="https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz"
FD_SHA256_amd64_musl=e3257d48e29a6be965187dbd24ce9af564e0fe67b3e73c9bdcd180f4ec11bdde
FD_SHA512_amd64_musl=9ca6ea369ded380edbb7ad706e034d77da3d66661ec5dd1ea7d3992ec54be854a3de84535ace03cb4f6a01751ec5c1b24e36427d14b60503abe51597c39c44af
FD_URL_arm64_gnu="https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-aarch64-unknown-linux-gnu.tar.gz"
FD_SHA256_arm64_gnu=6c51f7c5446b3338b1e401ff15dc194c590bb2fa64fd43ff3278300f073adec5
FD_SHA512_arm64_gnu=96229ced8ee9b59b5f2e7fa15c3e0014d6009a6ce4f91abf5058981be512e1fefc803a46ab6a8db250f32bcd0eb97e1c70ca3f38e685476e782ce797d2a9099b
FD_URL_arm64_musl="$FD_URL_arm64_gnu"
FD_SHA256_arm64_musl=6c51f7c5446b3338b1e401ff15dc194c590bb2fa64fd43ff3278300f073adec5
FD_SHA512_arm64_musl=96229ced8ee9b59b5f2e7fa15c3e0014d6009a6ce4f91abf5058981be512e1fefc803a46ab6a8db250f32bcd0eb97e1c70ca3f38e685476e782ce797d2a9099b
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
JQ_SHA256_amd64_gnu=020468de7539ce70ef1bceaf7cde2e8c4f2ca6c3afb84642aabc5c97d9fc2a0d
JQ_SHA512_amd64_gnu=4fe084094351a27947fcad3f3fd9ce3e1a87adb9c12b623f3b12647a81d93918d058b296411a07022805641f855a4f68fa7f092e112c29058cb93bd8c67928c8
JQ_URL_amd64_musl="$JQ_URL_amd64_gnu"
JQ_SHA256_amd64_musl=020468de7539ce70ef1bceaf7cde2e8c4f2ca6c3afb84642aabc5c97d9fc2a0d
JQ_SHA512_amd64_musl=4fe084094351a27947fcad3f3fd9ce3e1a87adb9c12b623f3b12647a81d93918d058b296411a07022805641f855a4f68fa7f092e112c29058cb93bd8c67928c8
JQ_URL_arm64_gnu="https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-arm64"
JQ_SHA256_arm64_gnu=6bc62f25981328edd3cfcfe6fe51b073f2d7e7710d7ef7fcdac28d4e384fc3d4
JQ_SHA512_arm64_gnu=b1cdef9b4165362ba17f66b3b59e0dcc3c6d96be66768f66cef2aa7224e06b50c6cdf40ce4d63272ed5ec2d4a8392ab28e5a154ecdfa5b27f6c521868342e57a
JQ_URL_arm64_musl="$JQ_URL_arm64_gnu"
JQ_SHA256_arm64_musl=6bc62f25981328edd3cfcfe6fe51b073f2d7e7710d7ef7fcdac28d4e384fc3d4
JQ_SHA512_arm64_musl=b1cdef9b4165362ba17f66b3b59e0dcc3c6d96be66768f66cef2aa7224e06b50c6cdf40ce4d63272ed5ec2d4a8392ab28e5a154ecdfa5b27f6c521868342e57a
JQ_ARCHIVE=none
JQ_BIN_IN_ARCHIVE=.
JQ_INSTALL_AS=/usr/local/bin/jq
JQ_SMOKE="jq --version"
JQ_SIG_TYPE=shasums-plain
JQ_SIG_URL="https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/sha256sum.txt"

# ----- delta (git-delta) ----- Rust tarball; gnu+musl for amd64.
# Upstream gnu binary needs glibc 2.34+; older distros fall through to
# the musl variant automatically (delta has musl variants pinned).
DELTA_GLIBC_MIN=2.34
DELTA_VERSION=0.19.2
DELTA_URL_amd64_gnu="https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
DELTA_SHA256_amd64_gnu=8e695c5f586a8c53d6c3b01be0b4a422ed218bfed2a56191caebe373a1c18ab2
DELTA_SHA512_amd64_gnu=bd4352df82341d4af127659fca4d1331519d504ef292311457b20e5fa9de76876512af7e583cd03ceccd8a2713f923b65c6a78d9e95b21d39b7f8dfae06347bc
DELTA_URL_amd64_musl="https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-x86_64-unknown-linux-musl.tar.gz"
DELTA_SHA256_amd64_musl=f1ea01ca7728ce3462debc359f39dfc7cbbc1a63224b71fefabf92042864aa1b
DELTA_SHA512_amd64_musl=b9c847f7bca0216b9973f4a7575b9afe91a38aee776632da932a0854317d5c241ed566e2409c5e4de15bbf45836eaef6dc31aa61720c9bb4d3c92966d86d84d3
DELTA_URL_arm64_gnu="https://github.com/dandavison/delta/releases/download/${DELTA_VERSION}/delta-${DELTA_VERSION}-aarch64-unknown-linux-gnu.tar.gz"
DELTA_SHA256_arm64_gnu=0bfce159a5cddd5feb3d6db4a616d883ff51253ce08ac7ec11cb1d208cfaab9e
DELTA_SHA512_arm64_gnu=d968be3c19cd085fede1a75b7d4d7c20e993339b495740587e9f9e3bd635e5f68f5429ff939da02eabf1f3dc2cbd7d8a2318f0179de26e8bd699b416b01679c8
DELTA_URL_arm64_musl="$DELTA_URL_arm64_gnu"
DELTA_SHA256_arm64_musl=0bfce159a5cddd5feb3d6db4a616d883ff51253ce08ac7ec11cb1d208cfaab9e
DELTA_SHA512_arm64_musl=d968be3c19cd085fede1a75b7d4d7c20e993339b495740587e9f9e3bd635e5f68f5429ff939da02eabf1f3dc2cbd7d8a2318f0179de26e8bd699b416b01679c8
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
LNAV_SHA256_amd64_gnu=9d146d1da2af005a77920afff5da96d2ae0771ee25450b0954b27de95e7f0f57
LNAV_SHA512_amd64_gnu=8f77b669d7a3b331dafe20d1b2202bc4fd805c897e3d934fd4a7d5dbf272aecfb75b6fd5f7f5cdab260d7f8de0b8d289a8d54f34a59d1fceb0e8512135a12174
LNAV_URL_amd64_musl="$LNAV_URL_amd64_gnu"
LNAV_SHA256_amd64_musl=9d146d1da2af005a77920afff5da96d2ae0771ee25450b0954b27de95e7f0f57
LNAV_SHA512_amd64_musl=8f77b669d7a3b331dafe20d1b2202bc4fd805c897e3d934fd4a7d5dbf272aecfb75b6fd5f7f5cdab260d7f8de0b8d289a8d54f34a59d1fceb0e8512135a12174
LNAV_URL_arm64_gnu="https://github.com/tstack/lnav/releases/download/v${LNAV_VERSION}/lnav-${LNAV_VERSION}-linux-musl-arm64.zip"
LNAV_SHA256_arm64_gnu=027e9f540567cd0e9ba00335ab9be0275a414b14608e10d49dc2d6a2633aa546
LNAV_SHA512_arm64_gnu=864fd407bd7646b84c381d0e44c09d26897c3acf33c9d629de5d74a4bd9ab762503c40192fd41ff68f9c156a7a2900e08472528ca4a4f122bd8ab5794dffb083
LNAV_URL_arm64_musl="$LNAV_URL_arm64_gnu"
LNAV_SHA256_arm64_musl=027e9f540567cd0e9ba00335ab9be0275a414b14608e10d49dc2d6a2633aa546
LNAV_SHA512_arm64_musl=864fd407bd7646b84c381d0e44c09d26897c3acf33c9d629de5d74a4bd9ab762503c40192fd41ff68f9c156a7a2900e08472528ca4a4f122bd8ab5794dffb083
LNAV_ARCHIVE=zip
LNAV_BIN_IN_ARCHIVE="lnav-${LNAV_VERSION}/lnav"
LNAV_INSTALL_AS=/usr/local/bin/lnav
LNAV_SMOKE="lnav --version"

# ----- gron ----- Go binary (static); flat tarball.
GRON_VERSION=0.7.1
GRON_URL_amd64_gnu="https://github.com/tomnomnom/gron/releases/download/v${GRON_VERSION}/gron-linux-amd64-${GRON_VERSION}.tgz"
GRON_SHA256_amd64_gnu=ca0335826b02b044fa05d7e951521e45c6ced1c381a73ed5803450088e18bf22
GRON_SHA512_amd64_gnu=a707e6a7f241f7495809cd4be8f47c961c51a4824a8cce9c6be7589198c09ba54520d7a42e9ab9ac3a754e59f00e87fb790b94ef903fbe58a107561b97218364
GRON_URL_amd64_musl="$GRON_URL_amd64_gnu"
GRON_SHA256_amd64_musl=ca0335826b02b044fa05d7e951521e45c6ced1c381a73ed5803450088e18bf22
GRON_SHA512_amd64_musl=a707e6a7f241f7495809cd4be8f47c961c51a4824a8cce9c6be7589198c09ba54520d7a42e9ab9ac3a754e59f00e87fb790b94ef903fbe58a107561b97218364
GRON_URL_arm64_gnu="https://github.com/tomnomnom/gron/releases/download/v${GRON_VERSION}/gron-linux-arm64-${GRON_VERSION}.tgz"
GRON_SHA256_arm64_gnu=5d1d4764723a0f768d9ddef0685a052f564c8bbf5e475382342faf4224a07d80
GRON_SHA512_arm64_gnu=8010d276dae57a0efec2e526f2d3799f3014dd92fad05b5fecdd3c2bc25d641a3275b29f1f58e2ec69386ffb5ed51ae37be2c8eaaff9abb190eb8c7850081080
GRON_URL_arm64_musl="$GRON_URL_arm64_gnu"
GRON_SHA256_arm64_musl=5d1d4764723a0f768d9ddef0685a052f564c8bbf5e475382342faf4224a07d80
GRON_SHA512_arm64_musl=8010d276dae57a0efec2e526f2d3799f3014dd92fad05b5fecdd3c2bc25d641a3275b29f1f58e2ec69386ffb5ed51ae37be2c8eaaff9abb190eb8c7850081080
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
TEALDEER_SHA256_amd64_gnu=6f2fad4435e0110484d3f25cdc4bf20129dae03238f32d06ebdd00bdc50ae2ed
TEALDEER_SHA512_amd64_gnu=3c692ce6f9e3be41ebe0e1da0877698a7f5cf2dfa5b77250a79ee0dd7df05749da1163bd89c010c2d7732c9fd332c22370344904553a1d4219d76a6e00bbf540
TEALDEER_URL_amd64_musl="$TEALDEER_URL_amd64_gnu"
TEALDEER_SHA256_amd64_musl=6f2fad4435e0110484d3f25cdc4bf20129dae03238f32d06ebdd00bdc50ae2ed
TEALDEER_SHA512_amd64_musl=3c692ce6f9e3be41ebe0e1da0877698a7f5cf2dfa5b77250a79ee0dd7df05749da1163bd89c010c2d7732c9fd332c22370344904553a1d4219d76a6e00bbf540
TEALDEER_URL_arm64_gnu="https://github.com/tealdeer-rs/tealdeer/releases/download/v${TEALDEER_VERSION}/tealdeer-linux-aarch64-musl"
TEALDEER_SHA256_arm64_gnu=09d4506b3ba2efe7376e3a5ce1238aa5e6c33ae6f2532c190156540f6c4e7d69
TEALDEER_SHA512_arm64_gnu=5f792e15c6fb23d9a3eae8f563cbfcd3a0d799e6ca7cf5a47b700c0a5b09ffca7caa33e801ef1c4fbd51a2ef20504bea91bde2e5a160cb0504183eb274b69475
TEALDEER_URL_arm64_musl="$TEALDEER_URL_arm64_gnu"
TEALDEER_SHA256_arm64_musl=09d4506b3ba2efe7376e3a5ce1238aa5e6c33ae6f2532c190156540f6c4e7d69
TEALDEER_SHA512_arm64_musl=5f792e15c6fb23d9a3eae8f563cbfcd3a0d799e6ca7cf5a47b700c0a5b09ffca7caa33e801ef1c4fbd51a2ef20504bea91bde2e5a160cb0504183eb274b69475
TEALDEER_ARCHIVE=none
TEALDEER_BIN_IN_ARCHIVE=.
TEALDEER_INSTALL_AS=/usr/local/bin/tldr
TEALDEER_SMOKE="tldr --version"
TEALDEER_POSTINSTALL_HOOK=tealdeer_postinstall

# ----- toybox ----- Rob Landley's static musl multi-call binary; "last-ditch
# coreutils" for the offline-bundle scenario (target host so broken that mv,
# cp, chmod are missing). Same single binary works on glibc and musl. The
# binary is installed at /usr/local/bin/toybox but NOT symlinked to coreutil
# names — invoke as `toybox <cmd>` (e.g. `toybox cp`), or run
# `toybox --install -s /usr/local/bin` manually to opt into symlinks. We do
# not auto-symlink because shadowing system coreutils on a healthy box would
# be disastrous. Upstream publishes no signatures or checksums file — the
# inline SHA256+SHA512 pins are the only verification (acceptable for a
# rescue tool; same-channel risk is inherent to the upstream's choice).
TOYBOX_VERSION=0.8.13
TOYBOX_URL_amd64_gnu="https://landley.net/toybox/bin/toybox-x86_64"
TOYBOX_SHA256_amd64_gnu=8c98795a15db31ea55c8065fed379db3669766b7a714c46b009d8bfb87b25ffd
TOYBOX_SHA512_amd64_gnu=bae01b3bb5c617216bee0dc8152ee2b4d88f03e0c8e5f468520a60c636ce1444d6042d4ae78209bfb46184d44d3dbf12af8ec6742703a0abbe16e0c7fbd2e970
TOYBOX_URL_amd64_musl="$TOYBOX_URL_amd64_gnu"
TOYBOX_SHA256_amd64_musl=8c98795a15db31ea55c8065fed379db3669766b7a714c46b009d8bfb87b25ffd
TOYBOX_SHA512_amd64_musl=bae01b3bb5c617216bee0dc8152ee2b4d88f03e0c8e5f468520a60c636ce1444d6042d4ae78209bfb46184d44d3dbf12af8ec6742703a0abbe16e0c7fbd2e970
TOYBOX_URL_arm64_gnu="https://landley.net/toybox/bin/toybox-aarch64"
TOYBOX_SHA256_arm64_gnu=b3508e5f51a0d429c1bda9d500d98d97dc0b86571762eeb099495eb238a8c52a
TOYBOX_SHA512_arm64_gnu=cccb0bb55926727ef0ba86f66a19f913daffe8667d44676d491d6894436f6b69caad9b202532f81e693299e4c135fba3e6963f135ca6c40fa6c54a008193cf5d
TOYBOX_URL_arm64_musl="$TOYBOX_URL_arm64_gnu"
TOYBOX_SHA256_arm64_musl=b3508e5f51a0d429c1bda9d500d98d97dc0b86571762eeb099495eb238a8c52a
TOYBOX_SHA512_arm64_musl=cccb0bb55926727ef0ba86f66a19f913daffe8667d44676d491d6894436f6b69caad9b202532f81e693299e4c135fba3e6963f135ca6c40fa6c54a008193cf5d
TOYBOX_ARCHIVE=none
TOYBOX_BIN_IN_ARCHIVE=.
TOYBOX_INSTALL_AS=/usr/local/bin/toybox
TOYBOX_SMOKE="toybox --version"

# ----- b3sum (BLAKE3 reference CLI) ----- fast modern cryptographic hash;
# pairs with the zstd/lz4/xxhsum trio in universal_pkgs for the
# tar | b3sum / xxhsum --check / etc. pipelines from jolynch's
# "fast data algorithms" post. Upstream ships a static-pie linked
# amd64-only binary; arm64 and musl fall through to the distro package
# via _reg_fallback (b3sum is in Debian 12+, Ubuntu 22.04+, Fedora 40+,
# Arch, Alpine, openSUSE Tumbleweed, Void, Kali, brew). Older RHEL-family
# distros without b3sum in their repos surface as a Known limitation.
B3SUM_VERSION=1.8.5
B3SUM_URL_amd64_gnu="https://github.com/BLAKE3-team/BLAKE3/releases/download/${B3SUM_VERSION}/b3sum_linux_x64_bin"
B3SUM_SHA256_amd64_gnu=f50bce4fc682c2eba7e417fdc271c3e7ea6e9511568213878dbf2c115facf6f4
B3SUM_SHA512_amd64_gnu=0437c3a2653bf8783f2f627285944fea213edf813b0daf6f4f3af552ade090f43d9c8e7d50bd4cc8427c9bbf5a3baedff602a3dfe9a201a6ba31f65faa877f65
# amd64-musl: BLAKE3's release binary is static-pie linked and works
# on musl in practice, but we pin only the gnu URL — if you're on
# Alpine and want b3sum, the distro package is canonical there anyway.
# arm64-gnu, arm64-musl: no upstream binary; fall through to pkg.
B3SUM_ARCHIVE=none
B3SUM_BIN_IN_ARCHIVE=.
B3SUM_INSTALL_AS=/usr/local/bin/b3sum
B3SUM_SMOKE="b3sum --version"
B3SUM_FALLBACK_PKG="b3sum"

# REGISTRY_TOOLS is the canonical list of tools handled by the engine. install.sh
# sources this file, reads this variable, and hands it to registry_fetch_all +
# registry_install_all. Adding a new tool means: (1) append a block above,
# (2) add the lowercase name to this list, (3) delete the now-obsolete
# lib/tools/<tool>.sh if any.
REGISTRY_TOOLS="b3sum bat cheat delta eza fd fish fzf gh gopass gron helix jq lazygit lnav lsd micro neovim qsv ripgrep starship tealdeer toybox zoxide"
