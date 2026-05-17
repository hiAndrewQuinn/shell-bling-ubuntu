#!/bin/sh
# Experimental: openSUSE Tumbleweed support. Tumbleweed's repos are rolling
# and tend to track upstream closely, so most modern tools (lsd, eza, helix,
# lazygit, gh, starship, zoxide, gopass, neovim) are available via zypper.
#
# CODENAME is either "tumbleweed" or "leap" — set by lib/detect.sh after
# normalizing ID=opensuse-tumbleweed → DISTRO=opensuse. Leap users get the
# same package list; anything missing on Leap falls through to the per-tool
# installer's GitHub-release path the same way Fedora does.

platform_opensuse_universal_pkgs() {
  # Anything in the registry (lib/registry.sh) is excluded — the registry
  # installs the upstream binary directly.
  echo "fish curl git vim tmux tree htop kitty xclip \
        gcc gcc-c++ make nodejs unzip xz \
        helix fzf"
}
