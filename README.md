# Shell Bling Ubuntu

A few shell scripts to get us some command-line niceties, for a fresh new Ubuntu installation.

* [Quickstart](#quickstart)
* [FAQ](#faq)
  + [What versions of Ubuntu does it work on?](#what-versions-of-ubuntu-does-it-work-on)
  + [What does it come with?](#what-does-it-come-with)
  + [Can I run this on a live USB?](#can-i-run-this-on-a-live-usb)
  + [Does this work on Ubuntu Server?](#does-this-work-on-ubuntu-server)

## 📹 Video - silent install, 2023.12.06

[Ubuntu-04-screen0_10x.webm](https://github.com/hiAndrewQuinn/shell-bling-ubuntu/assets/53230903/916e83a1-ba33-4969-a477-d1e1d149e79c)


The above is 10x to give a feel for how the commands work, it usually takes 5 to 10 minutes. [Normal-speed video here.](https://www.youtube.com/watch?v=dytkLqD674k)



## Quickstart

_From a brand spanking fresh new install of **Ubuntu 24.04**!_

### (optional) Bless your efforts

Before you begin whatever you're doing, take a deep breath, and [say](https://www.youtube.com/watch?v=mFo5UxECKA4)

    *Satellite from days of old, lead me to your access code.*

### Get the bling

```bash
sudo apt update
sudo apt install -y curl   # well it can't all be in a script!
curl https://raw.githubusercontent.com/hiAndrewQuinn/shell-bling-ubuntu/main/shell-bling-sudo.bash | sudo bash
```

Close your terminal, and use `Ctrl+Alt+T`. This time you should open into the Kitty terminal emulator, not the stock Ubuntu one.

```bash
curl https://raw.githubusercontent.com/hiAndrewQuinn/shell-bling-ubuntu/main/shell-bling-user.bash | bash

chsh -s $(which fish)
````

Close and reopen your terminal again.

```fish
# ⚠️ This will ask you DYNAMICALLY to pick your text editor.
curl https://raw.githubusercontent.com/hiAndrewQuinn/shell-bling-ubuntu/main/shell-bling.fish | fish
```

Close and reopen your terminal one more time.

Then run `nvim`. You should see it pop up with all the neat little icons.

![VirtualBox_ubuntu-golden-02_12_10_2023_20_46_36-no_copilot](https://github.com/hiAndrewQuinn/shell-bling-ubuntu/assets/53230903/bb79a4e1-3aed-4f2c-b1f8-efa4789d3850)


### (optional) Add Copilot to Neovim

LazyVim was the only Neovim setup that had instructions for integrating it with Github Copilot last I checked, and now it's even easier
to install.

1. Hit `e` to bring up "Lazy Extras". (It might also be `x` on your machine, look at the screen!)
2. Go to `coding.copilot` and hit `x` to install it. Then `:q`uit Neovim and restart it.
3. Finally, run `:Copilot auth` to start the authentication process.

![VirtualBox_ubuntu-golden-02_12_10_2023_20_46_20](https://github.com/hiAndrewQuinn/shell-bling-ubuntu/assets/53230903/e4c3f3bc-9bc3-4939-89c1-98a527560f95)


## FAQ

### What versions of Ubuntu does it work on?

| ✅/⚠️/❌ | Ubuntu version | YouTube video | ISO image SHA1 hash | ISO image MD5 hash | Date tested (YYYY-MM-DD) | SBU Git commit tested |
|----------|----------------|---------------|---------------------|--------------------|--------------------------|-----------------------|
| ✅       | 24.04.02       |               | 5ebad9f44adaf55f40d9a5430f9a02b655ddfd4b | 094aefdb1dbbdad8aa99600f8413789b | 2025-06-27 | 894e01bb1c1f271529a5f45c9f10262c6a7bf986 |

I test these scripts on a best-effort basis, when I have time. To test them I:

1. Download a fresh Ubuntu ISO from ubuntu.com;
2. Set it up in a fresh VirtualBox machine;
3. Clone that VM to a new test install VM; and
4. Run through the instructions exactly as they are above.

If everything looks hunky dory, I add a ✅ to the table above.
Then I clone the VM again, turn on video recording, do a full installation, and
upload it to Youtube. Finally I put *that* install into the table above.

What do I mean by "hunky dory"? Mostly I just test out all of the commands
below by hand. The scripts are intentionally kept as simple as I can possibly
make them, so that even in the event something breaks, it is possible for you,
dear user, to quickly debug it without actually needing to know how e.g. Ansible
works.

### What does it come with?

Look in the scripts and see for yourself! But here's a quick one-line explanation of everything in here so far, and why you might find it useful:

#### The Holy Trinity
- [fzf](https://github.com/junegunn/fzf): **Fuzzy search _anything_.** The best thing since sliced bread. I love `fzf` so much I have [a whole blog post](https://andrew-quinn.me/fzf/) about it!
  - Before you ask, **yes, this comes with the keybindings too!** `Ctrl+R` search in fish and `Alt-C` should work out of the box.
- [fd](https://github.com/sharkdp/fd): **Fastest find in the West.** A simple, fast, and user-friendly alternative to the classic "find" command.
  - Works _exceptionally_ well with `fzf` to find that specific file, whose name you know but just can't pin down, 7 or 8 subdirectories deep!
  - ⚠️ Note that we **_do_ symlink this to the `fd` command**, which you have to do as an extra step on Ubuntu. (Otherwise it's just linked as `fdfind`, and really, who's going to go to the effort of typing _two more letters_ just to use something better than `find`?)
- [ripgrep](https://github.com/BurntSushi/ripgrep): **Fastest grep in the West.** A line-oriented search tool that recursively searches your current directory for a regex pattern, faster than most other tools.
  - Works _exceptionally_ well with `fzf` to find that specific line, in that specific file, 7 or 8 subdirectories deep!
  - ⚠️ Note that **it is called `rg` at the command line**, as in `grep whatever` == `rg whatever`. _Not_ `ripgrep whatever`!

#### Shells and Terminal Utilities
- [fish](https://fishshell.com/): The **nicest out-of-the-box shell I've ever used**. Gives you autocomplete, in-shell highlighting, the works!
- [starship](https://starship.rs): A **minimal, blazing-fast, and infinitely customizable prompt** for any shell! Shows the info you need while staying sleek and minimal. I like it especially because it works with bash, fish, PowerShell, elvish, you name it!
- [tmux](https://github.com/tmux/tmux/wiki): A terminal multiplexer. Lets you work with **multiple terminal sessions in one window** and **long-running, detachable SSH sessions**, if, like me, you sometimes just want to remote into a machine once every 2 weeks for 6 months at a time without losing your place.
- [kitty](https://sw.kovidgoyal.net/kitty/): A fast, feature-rich, GPU-based terminal emulator. (And the best one I know of which **supports ligatures!**)
  - And to _get_ those ligatures, we set Kitty up to use [Fira Code by default](https://github.com/tonsky/FiraCode) everywhere!
- [xclip](https://github.com/astrand/xclip): A command-line interface to the X11 clipboard, allowing you to **copy and paste between the terminal and GUI apps by piping to it.** Comes in handy way too often for me to live without!

#### Help Text ... Helpers
- [tldr](https://tldr.sh/): **Simplified and community-driven man pages**. It offers quick references to common command-line tasks.
- [cheat](https://github.com/cheat/cheat): Allows you to **create and view interactive cheatsheets** on the command-line. It was designed to help remind *nix system administrators of options for commands that they use frequently, but not frequently enough to remember.

#### File and Directory Utilities
- [zoxide](https://github.com/ajeetdsouza/zoxide): **A smarter `cd`** that learns your habits and preferences over time!
- [lsd](https://github.com/Peltoche/lsd): A **modern version of the `ls` command** with a lot of improvements such as color support, icons, and more.
- [tree](http://mama.indstate.edu/users/ice/tree/): Displays directories as trees (with optional color and HTML output). I'm just always surprised this isn't installed by default!

#### Text Editors and Viewers
- [bat](https://github.com/sharkdp/bat): **cat but with syntax highlighting**. I'm entirely serious, it's a big improvement!
- [micro](https://github.com/zyedidia/micro): **Finally, a command-line editor for non-Vimmers!** A modern and intuitive terminal-based text editor, similar to (but much nicer than!) the default `nano`.
- [vim](https://www.vim.org/): **The OG.** An advanced text editor that's been around for decades, allowing efficient text editing with keyboard shortcuts.
- [neovim](https://neovim.io/): A modern refactor of Vim, which has since spawned its own _huge_ community.
  - ⚠️ **This installs the latest _unstable_ Neovim version,** not the woefully out-of-date one that comes by default with Ubuntu. We need this because we also install...
    - [LazyVim](https://www.lazyvim.org), the only "full-featured" Neovim setup that actually [has instructions on how to install Copilot](https://www.lazyvim.org/extras/coding/copilot). (It's possible in all of them, but actually being documented was what won me over!)
- [helix](https://helix-editor.com/): **Post-modern, zero-config.** A terminal-based text editor that's _actually_ modern and intuitive, with a focus on speed and minimalism.

#### Development and Coding Tools
- [git](https://git-scm.com/): **The GOAT.** The most widely used distributed VCS on the planet. Always surprised this doesn't come pre-installed!
  - [git-delta](https://github.com/dandavison/delta): Never get confused by `git diff` again! A viewer for git and diff output with syntax highlighting and line numbers.
- [lazygit](https://github.com/jesseduffield/lazygit): The best full-terminal display I've ever seen for Git. Integrates with LazyVim out of the box, too, just do `Space-g-g`.
- [entr](https://github.com/eradman/entr): **Run $COMMAND when $FILE changes.** _Crazy_ useful for setting up quick little auto-compiling/testing loops during development, especially if you're using [tmux](https://github.com/tmux/tmux/wiki) or [kitty](https://sw.kovidgoyal.net/kitty/)'s tabs.

#### Data Manipulation and Viewing
- [jq](https://stedolan.github.io/jq/): A lightweight and flexible command-line JSON processor. A must-have for parsing and manipulating JSON data.
- [gron](https://github.com/tomnomnom/gron): **Make JSON greppable!** by transforming it into discrete, greppable assignments. Pairs surprisingly nicely with `jq` if you use it to figure out what to actually _write_ in `jq`.
- [csvkit](https://csvkit.readthedocs.io/en/latest/): **Your CSV scalpels,** because we all know what file format the business world _really_ runs on. (Plenty of other great options here! `xsv`, `miller`, and `csv-to-sqlite` to name a few! I chose this just because I like having separate commands for `csvjoin`, `csvcut`, etc.)

#### System Monitoring and Search
- [htop](https://hisham.hm/htop/): An interactive process viewer, providing a real-time, color-coded overview of running processes.
- [lnav](https://lnav.org/): An **advanced log file viewer** for the small-scale. It helps you navigate through your log files, and it can automatically identify and color-highlight different log file structures.
- [bottom](https://github.com/ClementTsang/bottom): **CPU usage graphs? In _my_ terminal?** It's more likely than you think.


#### Things Other Things Here Need To Work Right
- [curl](https://curl.se/): A command-line tool for getting or sending data using URL syntax. It supports multiple protocols, making it a go-to for many web operations. Needed to, well, `curl` the scripts here.
- [gcc](https://gcc.gnu.org/): The GNU Compiler Collection, providing compilers for various programming languages. Needed for some of the stuff [LazyVim](https://www.lazyvim.org) installs.
- [make](https://www.gnu.org/software/make/): A utility that automatically builds executable programs and libraries from source code. Needed for one of the packages [LazyVim](https://www.lazyvim.org) installs.
- [g++](https://gcc.gnu.org/): The **GNU C++ compiler**. It's an essential tool for compiling C++ code. Needed for some of the stuff [LazyVim](https://www.lazyvim.org) installs.
- [nodejs](https://nodejs.org/): A **JavaScript runtime** built on Chrome's V8 JavaScript engine. Essential for a variety of JavaScript tasks and development workflows. Needed for LazyVim's Copilot server.


If I've forgotten anything, let me know!

### Can I run this on a live USB?

**I don't recommend it**; for some reason, every time I've tried these on a Live USB in a VM with 8 GB of RAM allocated to it, the VM shuts down mysteriously. Running `watch free -h` hasn't revealed to me any obvious out of RAM error, so I'm stumped! Can _you_ help me debug this mysterious issue?

### Does this work on Ubuntu Server?

**Yes!** Here's a Raspberry Pi SSH connection (using `kitty +kitten ssh` for [true convenience](https://sw.kovidgoyal.net/kitty/kittens/ssh/)) running Ubuntu Server 23.10. I had no issues at all installing it:

![image](https://github.com/hiAndrewQuinn/shell-bling-ubuntu/assets/53230903/a560e67d-27d2-4563-915b-2f3f40213851)

![image](https://github.com/hiAndrewQuinn/shell-bling-ubuntu/assets/53230903/7ea13026-eddf-40be-b817-5dac1eeaf5b1)

### Where else does this work?

Here's a list of places your humble author has ran these scripts and found them to work unaltered:

- [Laravel](https://laravel.com/)'s [Homestead](https://laravel.com/docs/8.x/homestead) VM.

## Testing

### Docker-based Testing

You can test the installation scripts in a containerized environment:

```bash
# Build the Docker image
docker build -t shell-bling-test .

# Run the test suite
docker run --rm shell-bling-test bash /home/testuser/test-installations.sh

# Or run interactively to explore
docker run -it --rm shell-bling-test fish
```

### Manual Testing

The `test-installations.sh` script verifies that all tools are properly installed:

```bash
./test-installations.sh
```

This will check for the presence of all installed commands, configuration files, and proper symlink setup.
