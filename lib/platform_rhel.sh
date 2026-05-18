#!/bin/sh
# Experimental: RHEL family (Rocky, AlmaLinux, CentOS Stream, Amazon Linux).
# All four normalize to DISTRO=rhel in lib/detect.sh; the original ID is
# kept in CODENAME so per-distro divergences (e.g. AL2023 lacking EPEL)
# can still branch from this single platform file.
#
# Anything in lib/registry.sh is intentionally absent — the registry
# installs the upstream binary directly, so RHEL users get the same
# version as every other distro.

platform_rhel_universal_pkgs() {
  # AppStream + EPEL coverage. EPEL is wired in via preflight below;
  # wl-clipboard and kitty live in EPEL on Rocky/Alma/CentOS Stream.
  # `tar` is explicit because the Amazon Linux 2023 minimal image ships
  # without it, and the registry engine relies on tar for every .tar.gz /
  # .tar.xz extraction. No-op on Rocky / Alma / CentOS where tar is
  # already in the base.
  echo "curl git vim tmux tree htop xclip wl-clipboard \
        sqlite rsync tar \
        zstd lz4 xxhash \
        gcc gcc-c++ make nodejs unzip xz \
       "
}

platform_rhel_preflight() {
  # EPEL provides several of the universal packages (wl-clipboard, kitty,
  # etc.). Different RHEL clones reach it differently — branch by CODENAME:
  case "$CODENAME" in
    amzn)
      # AL2023 has no EPEL. Skip; the missing pkgs (wl-clipboard, kitty)
      # are non-fatal — wl-clipboard is desktop-only on the airgapped
      # AWS shape anyway.
      :
      ;;
    amzn-2)
      # Amazon Linux 2 reaches EPEL via amazon-linux-extras. Tolerate
      # failure — the extras command can be flaky on stale base images.
      sudo_run amazon-linux-extras install -y epel 2> /dev/null ||
        warn "amazon-linux-extras epel failed; wl-clipboard / kitty may be skipped"
      ;;
    centos7)
      # CentOS 7 EPEL repos still exist (vault.centos.org / fedoraproject
      # archive) but the default mirrorlist URLs in the EOL repos point
      # at unreachable hosts. Just attempt — falls through cleanly if
      # the mirror is gone. Many CentOS 7 boxes in the wild already
      # have EPEL configured anyway.
      pkg_install epel-release 2> /dev/null ||
        warn "epel-release unavailable on CentOS 7 (likely mirror dead); wl-clipboard / kitty may be skipped"
      ;;
    *)
      pkg_install epel-release 2> /dev/null ||
        warn "epel-release unavailable on $CODENAME — wl-clipboard / kitty may be skipped"
      ;;
  esac
  # kitty is GUI; not always in minimal containers — graceful skip.
  pkg_install kitty 2> /dev/null || warn "kitty unavailable; skipping"
}

# RHEL family known-unavailable: same glibc story as Debian 11 / Ubuntu 20.04
# applies to Rocky 9 / Alma 9 / CentOS Stream 9 (glibc 2.34 — exactly at the
# edge for most of our pinned binaries). RHEL 10 / CS 10 ship glibc 2.39
# and are fine. AL2023 ships glibc 2.34. We don't yet have specific
# knowledge of failures here — leave empty until smoke testing surfaces
# something concrete.
platform_rhel_known_unavailable() {
  # Case key is "${CODENAME}:${MAJOR_VERSION}" — codename alone isn't
  # specific enough since e.g. Rocky 8/9/10 all share CODENAME=rocky.
  case "${CODENAME}:${VERSION_ID%%.*}" in
    rocky:8 | alma:8)
      printf '%s\n' \
        'helix    upstream tarball needs glibc 2.34+ (Rocky/Alma 8 ships 2.28); no upstream musl build; not in base or EPEL 8.' \
        'neovim   upstream tarball needs glibc 2.34+; dnf installs nvim 0.8.0 from EPEL 8 instead. LazyVim auto-skipped (needs nvim >= 0.11).'
      ;;
    centos7:* | amzn-2:*)
      # Pre-2.28 glibc territory (CentOS 7 = 2.17, AL2 = 2.26). Both helix
      # and neovim's upstream binaries are far out of reach; bat/fd/eza/
      # lsd/starship now use their musl variants via GLIBC_MIN, so they
      # install cleanly. Old nvim from the distro repos is good enough
      # for muscle-memory; LazyVim auto-skips.
      printf '%s\n' \
        'helix    upstream tarball needs glibc 2.34+ (this distro ships <2.28); no upstream musl build; not packaged here.' \
        'neovim   upstream tarball needs glibc 2.34+; distro package installs an older nvim (<0.11). LazyVim auto-skipped.'
      ;;
  esac
}
