#!/usr/bin/fish

# Finally, we're at the finish line. We have fish as our default shell, so now it's time to integrate some stuff.
# TO BE RUN AS THE NORMAL USER.

# Install fzf and the keybindings.
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all
fzf_key_bindings

# Install starship and add it to config.fish
curl -sS https://starship.rs/install.sh | sh -s -- --yes

echo 'starship init fish | source' >>~/.config/fish/config.fish

echo 'INSTALLATION COMPLETE. Please close and open your shell.'
