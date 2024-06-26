#!/usr/bin/fish

# Finally, we're at the finish line. We have fish as our default shell, so now it's time to integrate some stuff.
# TO BE RUN AS THE NORMAL USER.

# Add ~/.local/bin to your Fish path. (This is needed so that
# anything, most importantly our `fd` symlink to `fdfind`,
# works as intended.

fish_add_path --universal ~/.local/bin

# Alias batcat to bat. (It's a little different in the Fish shell - I would say cleaner 💅)
alias bat batcat
funcsave bat

# Add a 2 second penalty, just because this keeps tripping me up.
alias ripgrep 'set_color red; echo -n "2 second penalty :: "; set_color normal; echo -n "The binary is called "; set_color green; echo -n "rg"; set_color normal; echo "."; sleep 2; rg'
funcsave --quiet ripgrep

# Install fzf and the keybindings.
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all

# Install starship and add it to config.fish
curl -sS https://starship.rs/install.sh | sh -s -- --yes
echo 'starship init fish | source' >>~/.config/fish/config.fish

# Install the latest zoxide and source it in the config.fish
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
echo 'zoxide init fish | source' >>~/.config/fish/config.fish




set editors_descriptions '
micro    # 🕊️ Best for beginners.    📉 Low learning curve.
vim      # 🥷 The original.          📈 High learning curve.
nvim     # 💯 Latest and greatest.   📈 High learning curve.
hx       # 🧬 An elegant weapon.     🕴️ Fun learning curve.'

# Use fzf to prompt the user to select an editor
set selected_editor_description (echo $editors_descriptions | fzf --header "Select your default text editor ✍️📑✒️")


# If an editor was selected, extract the editor name and set it as the default editor for fish
if test -n "$selected_editor_description"
    set selected_editor (echo $selected_editor_description | cut -d' ' -f1)
    echo "set -gx EDITOR $selected_editor" >>~/.config/fish/config.fish
    echo "set -gx VISUAL $selected_editor" >>~/.config/fish/config.fish
    git config --global core.editor $selected_editor
    set_color -o yellow
    echo "Default editor set to "(set_color -o green)"$selected_editor"(set_color -o yellow)"."
    set_color normal
else
    set_color -o red
    echo "No editor selected. No changes made."
    set_color normal
end


# Download the show_random_whatis.fish script
curl -sS https://raw.githubusercontent.com/hiAndrewQuinn/shell-bling-ubuntu/main/show_random_whatis.fish -o ~/.config/fish/functions/show_random_whatis.fish

# Append the custom fish_greeting to the config.fish

echo '' >>~/.config/fish/config.fish
echo '' >>~/.config/fish/config.fish
echo '# Courtesy of Shell Bling Ubuntu.' >>~/.config/fish/config.fish
echo 'function fish_greeting' >>~/.config/fish/config.fish
echo '    echo -e "\033[34mWelcome to fish, the friendly interactive shell\033[0m"' >>~/.config/fish/config.fish
echo '    echo -e "Type \033[32mhelp\033[0m for instructions on how to use fish"' >>~/.config/fish/config.fish
echo '    echo' >>~/.config/fish/config.fish
echo '    show_random_whatis' >>~/.config/fish/config.fish
echo end >>~/.config/fish/config.fish

set_color -o yellow
echo 'INSTALLATION COMPLETE.'
echo ''
set_color -o green
echo 'Restart your shell one more time.'
set_color -o yellow
echo ''
echo 'Then try out your nifty new CLI keyboard shortcuts!'
echo ''
echo '- '(set_color -o blue)'Ctrl+R'(set_color -o yellow)' to do fuzzy searching over your shell history.    Example @ https://andrew-quinn.me/fzf/'
echo '- '(set_color -o blue)'Alt+C '(set_color -o yellow)' to do fuzzy searching to change directories.      Example @ https://andrew-quinn.me/fzf/'
echo '- '(set_color -o blue)'Alt+E '(set_color -o yellow)' to edit your next command in '(set_color -o green)"$selected_editor"(set_color -o yellow)'.                Example @ https://andrew-quinn.me/ctrl-x-ctrl-e/'
echo '         (Great for long commands!)'
echo ''
echo 'Happy coding! -hiAndrewQuinn'
set_color normal
