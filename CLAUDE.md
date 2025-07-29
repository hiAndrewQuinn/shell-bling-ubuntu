# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Shell Bling Ubuntu is a collection of shell scripts designed to enhance a fresh Ubuntu installation with modern command-line tools and utilities. The project consists of three main installation scripts that must be run in sequence.

## Installation Commands

The installation process involves three scripts that must be run in order:

1. **System-wide packages** (requires sudo):
   ```bash
   sudo apt update
   sudo apt install -y curl
   curl https://raw.githubusercontent.com/hiAndrewQuinn/shell-bling-ubuntu/main/shell-bling-sudo.bash | sudo bash
   ```

2. **User-specific setup** (run as normal user after reopening terminal):
   ```bash
   curl https://raw.githubusercontent.com/hiAndrewQuinn/shell-bling-ubuntu/main/shell-bling-user.bash | bash
   chsh -s $(which fish)
   ```

3. **Fish shell configuration** (run after switching to fish):
   ```fish
   curl https://raw.githubusercontent.com/hiAndrewQuinn/shell-bling-ubuntu/main/shell-bling.fish | fish
   ```

## Architecture

The installation is split into three phases to handle different permission requirements and shell environments:

- **shell-bling-sudo.bash**: Installs system packages via apt and snap, sets kitty as default terminal
- **shell-bling-user.bash**: Sets up user configurations, fonts, LazyVim, and prepares for fish shell
- **shell-bling.fish**: Configures fish shell with fzf, starship, zoxide, and sets default editor
- **show_random_whatis.fish**: Helper function that displays random tool descriptions on shell startup

## Key Features Installed

The scripts install and configure:
- Modern shell (fish) with enhanced prompt (starship)
- Terminal emulator (kitty) with FiraCode Nerd Font
- Search tools (fzf, fd, ripgrep)
- Text editors (vim, neovim with LazyVim, helix, micro)
- Development tools (git, lazygit, git-delta)
- System utilities (tmux, htop, bottom, tree)
- Data tools (jq, gron, csvkit)

## Testing

The project is tested on fresh Ubuntu installations in VirtualBox. Each supported version is documented in the README with SHA1/MD5 hashes and test dates.