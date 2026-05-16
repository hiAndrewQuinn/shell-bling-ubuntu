function show_random_whatis
    set commands fzf fd ripgrep fish starship tmux kitty xclip tldr cheat zoxide \
        lsd eza tree bat micro vim neovim helix git git-delta jq gron qsv \
        htop lnav curl lazygit gh uv gopass rustup go pass

    set -l descriptions_fzf "Fuzzy search anything!"
    set -l descriptions_fd "Fastest find in the West!"
    set -l descriptions_ripgrep "Fastest grep in the West!"
    set -l descriptions_fish "Nicest out-of-the-box shell I've ever used!"
    set -l descriptions_starship "Nice, fancy, helpful custom prompt!"
    set -l descriptions_tmux "Terminal multiplexer. Thank you OpenBSD!"
    set -l descriptions_kitty "Terminal emulator. Supports ligatures! <><~><>"
    set -l descriptions_xclip "Copy and paste from the command line!"
    set -l descriptions_tldr "Run 'tldr tldr' to see more!"
    set -l descriptions_cheat "Interactive cheatsheets."
    set -l descriptions_zoxide "Smarter cd. Now with extra recency bias!"
    set -l descriptions_lsd "Modern, fancy looking 'ls'!"
    set -l descriptions_eza "Even fancier 'ls' — Rust rewrite of exa."
    set -l descriptions_tree "Prints the filesystem as a tree!"
    set -l descriptions_bat "cat/less with syntax highlighting!"
    set -l descriptions_micro "Easy CLI editor, with normal shortcuts!"
    set -l descriptions_vim "The original!"
    set -l descriptions_neovim "Modern refactor of the original!"
    set -l descriptions_helix "The postmodern text editor!"
    set -l descriptions_git "Version control the Linus way!"
    set -l descriptions_git_delta "Nicer git diffing!"
    set -l descriptions_jq "The JSON Swiss Army knife!"
    set -l descriptions_gron "Make JSON greppable (or rg-able)!"
    set -l descriptions_qsv "Slice, dice, and stat CSVs. (xsv's spiritual successor.)"
    set -l descriptions_rustup "Manage your Rust toolchain. cargo install <thing> now works."
    set -l descriptions_go "The Go toolchain. go install <thing> now works."
    set -l descriptions_pass "Same as gopass — symlinked for muscle memory."
    set -l descriptions_htop "See your system's stats in technicolor!"
    set -l descriptions_lnav "Slice and dice everything in /var/log/!"
    set -l descriptions_curl "Download things from the web!"
    set -l descriptions_lazygit "TUI for git. Stage hunks without the headache."
    set -l descriptions_gh "GitHub from the command line."
    set -l descriptions_uv "Fast Python package + venv manager."
    set -l descriptions_gopass "pass, but modern. Drop-in compatible."

    set -l selected
    while test (count $selected) -lt 4
        set -l random_command (echo $commands | tr ' ' '\n' | shuf -n 1)
        if not contains $random_command $selected
            set selected $selected $random_command
        end
    end

    echo -e "\033[35mShell Bling\033[0m installed. Why not learn more about"
    echo
    for cmd in $selected
        set padded_cmd (printf "%-20s" $cmd)
        set description_var descriptions_(string replace -a '-' '_' $cmd)
        set description $$description_var
        echo -e "    \033[34m$padded_cmd\033[0m $description"
    end
    echo
    echo -e "today? Try \033[33mtldr <command>\033[0m or \033[33mcheat <command>\033[0m for ideas."
end
