#!/bin/sh
# Experimental: Fedora support. Most tools work via dnf or via the binary
# installers in lib/tools/*. This file holds Fedora-specific glue.

platform_fedora_universal_pkgs() {
  # Fedora package names. Some differ from Debian.
  echo "fish curl git ripgrep jq vim tmux tree htop bat fd-find kitty xclip \
        gcc gcc-c++ make nodejs git-delta lnav gron entr-doesnt-exist unzip \
        cheat lsd helix neovim eza gh starship zoxide tealdeer gopass \
        rustup golang"
  # Note: gron / cheat may need pip / COPR — pkg_install will tolerate
  # missing packages individually if you split the call; for simplicity the
  # caller can try each universal pkg one-by-one if the bulk install fails.
  # qsv comes from the GitHub release; rustup/golang are best-effort distro
  # packages but lib/tools/rustup.sh + lib/tools/go.sh will handle install.
}
