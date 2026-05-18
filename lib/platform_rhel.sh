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
        gcc gcc-c++ make nodejs unzip xz \
       "
}

platform_rhel_preflight() {
  # EPEL provides several of the universal packages (wl-clipboard, kitty,
  # etc.) on Rocky/Alma/CentOS Stream. Amazon Linux 2023 does NOT have a
  # working EPEL; the install just no-ops there and any EPEL-only package
  # falls through to the registry/static-binary path (or stays missing).
  case "$CODENAME" in
    amzn)
      # AL2023 has no EPEL. Skip; the missing pkgs (wl-clipboard, kitty)
      # are non-fatal — wl-clipboard is desktop-only on the airgapped
      # AWS shape anyway.
      :
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
  case "$CODENAME" in
    *)
      # No declared unavailable tools yet — populated as the test matrix
      # reveals specific known-impossible cases per (codename, version_id).
      :
      ;;
  esac
}
