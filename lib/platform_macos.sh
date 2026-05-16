#!/bin/sh
# Experimental: macOS support via Homebrew.

platform_macos_universal_pkgs() {
  echo "fish curl git ripgrep jq vim tmux tree htop bat fd kitty \
        gcc make node git-delta lnav csvkit gron entr cheat lsd \
        helix neovim eza gh starship zoxide tealdeer gopass uv \
        lazygit tldr fzf"
}

platform_macos_preflight() {
  _install_homebrew
}
