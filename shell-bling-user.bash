#!/usr/bin/bash

# Part 2!
#
# Everything in here is meant to be run as your normal user, not root.
#

# Starting off with a bit of a hack. If we want access to the
# things in ~/.local/bin without restarting the VM outright, we
# don't have much of a choice.
echo '' >>~/.bashrc
echo '# Check if $HOME/.local/bin is not already in the PATH' >>~/.bashrc
echo 'if [[ ! ":$PATH:" == *":$HOME/.local/bin:"* ]]; then' >>~/.bashrc
echo '  # It is not in the PATH, so prepend it' >>~/.bashrc
echo '  PATH="$HOME/.local/bin:$PATH"' >>~/.bashrc
echo 'fi' >>~/.bashrc
echo '' >>~/.bashrc
source ~/.bashrc

# Link fd to fdfind.
mkdir -p ~/.local/bin
ln -s $(which fdfind) ~/.local/bin/fd

# First, install the FiraCode Nerd Font.
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts && curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/FiraCode/Retina/FiraCodeNerdFont-Retina.ttf

# Next set up kitty to use Fira Code, with all the ligatures.
mkdir -p ~/.config/kitty
kitty +runpy 'from kitty.config import *; print(commented_out_default_config())' >~/.config/kitty/kitty.conf
sed -i 's/^# font_family .*/font_family    FiraCode Nerd Font/' ~/.config/kitty/kitty.conf
sed -i 's/^# disable_ligatures .*/disable_ligatures     never/' ~/.config/kitty/kitty.conf

# Now

# Install lazygit.
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin

# Install LazyVim for Neovim.
# required
mv ~/.config/nvim{,.bak}

# optional but recommended
mv ~/.local/share/nvim{,.bak}
mv ~/.local/state/nvim{,.bak}
mv ~/.cache/nvim{,.bak}

git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git

# Set git-delta as the default pager for git.
cat <<EOF >>~/.gitconfig

[core]
    pager = delta

[interactive]
    diffFilter = delta --color-only

[delta]
    navigate = true    # use n and N to move between diff sections
    light = false      # set to true if you're in a terminal w/ a light background color (e.g. the default macOS terminal)

[merge]
    conflictstyle = diff3

[diff]
    colorMoved = default
EOF

echo -e "\033[1m\033[93mPart 2 done. Now run\033[0m"
echo -e "\033[1m\033[93m\033[0m"
echo -e "\033[1m\033[93m    nvim\033[0m"
echo -e "\033[1m\033[93mto get LazyVim set up, then\033[0m"
echo -e "\033[1m\033[93m\033[0m"
echo -e "\033[1m\033[93m    chsh -s \$(which fish)\033[0m"
echo -e "\033[1m\033[93m\033[0m"
echo -e "\033[1m\033[93mas your normal user, to switch to the fish shell.\033[0m"
echo -e "\033[1m\033[93mThen close your terminal again, open it once more, and run\033[0m"
echo -e "\033[1m\033[93m\033[0m"
echo -e "\033[1m\033[93m    # ⚠️ This will ask you DYNAMICALLY to pick your text editor.\033[0m"
echo -e "\033[1m\033[93m    curl https://raw.githubusercontent.com/hiAndrewQuinn/shell-bling-ubuntu/main/shell-bling.fish | fish\033[0m"
echo -e "\033[1m\033[93m\033[0m"
