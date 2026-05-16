# Shell Bling

A curated set of command-line niceties for a fresh Ubuntu, Debian, Fedora, or
macOS install. One command, sudo password once, fzf pickers at the end.

## Quickstart

```sh
curl -fsSL https://raw.githubusercontent.com/hiAndrewQuinn/shell-bling-ubuntu/main/install.sh | sh
```

That's it. The script will:

1. Detect your platform.
2. Ask for your sudo password once (and keep the timestamp alive in the
   background).
3. Install everything silently.
4. Open two `fzf` pickers — one for your default editor, one for whether
   to switch your login shell to `fish`.
5. Print a friendly recap.

Close and reopen your terminal when it finishes.

## Supported platforms

| Platform                              | Tier         | x86_64 | arm64 |
| ------------------------------------- | ------------ | :----: | :---: |
| Ubuntu 22.04 / 24.04 / 26.04          | tier 1       |   ✅   |   ✅  |
| Debian 12 / 13                        | tier 1       |   ✅   |   ✅  |
| Fedora (current stable)               | experimental |   ✅   |   ✅  |
| macOS (Intel + Apple Silicon)         | experimental |   ✅   |   ✅  |
| WSL2 (Ubuntu/Debian under Windows)    | experimental |   ✅   |   ✅  |

Tier-1 platforms are tested in CI on every commit. Experimental platforms
are best-effort — please file issues.

## Try before you install

```sh
git clone https://github.com/hiAndrewQuinn/shell-bling-ubuntu
cd shell-bling-ubuntu
make dev DISTRO=ubuntu-24.04   # or debian-13, ubuntu-22.04, etc.
```

This drops you into an interactive shell inside a fresh container after the
installer runs. Great for kicking the tires.

## What's in the box

<details>
<summary><strong>The Holy Trinity</strong> — search, search, search</summary>

- **[fzf](https://github.com/junegunn/fzf)** — fuzzy search _anything_. `Ctrl+R` for history, `Alt+C` for cd.
- **[fd](https://github.com/sharkdp/fd)** — fast, friendly `find`. We symlink `fdfind` → `fd`.
- **[ripgrep](https://github.com/BurntSushi/ripgrep)** — `rg`, the fastest grep.

</details>

<details>
<summary><strong>Shells & terminals</strong></summary>

- **[fish](https://fishshell.com/)** — autocomplete + syntax highlighting out of the box.
- **[starship](https://starship.rs)** — fast, minimal, customizable prompt.
- **[tmux](https://github.com/tmux/tmux/wiki)** — terminal multiplexer.
- **[kitty](https://sw.kovidgoyal.net/kitty/)** — GPU-based terminal with ligature support, set up with FiraCode Nerd Font.
- **[xclip](https://github.com/astrand/xclip)** — pipe to/from the clipboard.

</details>

<details>
<summary><strong>Help & cheatsheets</strong></summary>

- **[tldr](https://tldr.sh/)** (via [tealdeer](https://github.com/dbrgn/tealdeer) when available) — simplified man pages.
- **[cheat](https://github.com/cheat/cheat)** — interactive cheatsheets.

</details>

<details>
<summary><strong>File & directory tools</strong></summary>

- **[zoxide](https://github.com/ajeetdsouza/zoxide)** — smarter `cd` that learns your habits.
- **[lsd](https://github.com/lsd-rs/lsd)** + **[eza](https://eza.rocks/)** — modern `ls` with icons & colors.
- **[tree](http://mama.indstate.edu/users/ice/tree/)** — directories as a tree.

</details>

<details>
<summary><strong>Editors</strong></summary>

- **[bat](https://github.com/sharkdp/bat)** — `cat` with syntax highlighting.
- **[micro](https://github.com/zyedidia/micro)** — easy terminal editor.
- **[vim](https://www.vim.org/)** + **[Neovim](https://neovim.io/)** with **[LazyVim](https://www.lazyvim.org)** starter.
- **[helix](https://helix-editor.com/)** — postmodern, zero-config editor.

</details>

<details>
<summary><strong>Dev & coding</strong></summary>

- **[git](https://git-scm.com/)** + **[git-delta](https://github.com/dandavison/delta)** — version control + pretty diffs.
- **[lazygit](https://github.com/jesseduffield/lazygit)** — git TUI.
- **[gh](https://cli.github.com/)** — GitHub CLI.
- **[uv](https://github.com/astral-sh/uv)** — fast Python package + venv manager.
- **[gopass](https://github.com/gopasspw/gopass)** — modern, `pass`-compatible password manager.

</details>

<details>
<summary><strong>Data wrangling</strong></summary>

- **[jq](https://stedolan.github.io/jq/)** + **[gron](https://github.com/tomnomnom/gron)** — JSON.
- **[csvkit](https://csvkit.readthedocs.io/)** — CSV scalpels.

</details>

<details>
<summary><strong>System & logs</strong></summary>

- **[htop](https://htop.dev/)** — process viewer.
- **[lnav](https://lnav.org/)** — interactive log file viewer.

</details>

<details>
<summary><strong>Compilers & runtimes (needed by LazyVim)</strong></summary>

`curl`, `gcc`, `g++`, `make`, `nodejs`.

</details>

## Environment variables

| Var                              | Effect                                                                                                                                                                  |
| -------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `SHELL_BLING_NONINTERACTIVE=1`   | Skip fzf pickers; default editor=`nvim`; `chsh` to fish without asking.                                                                                                 |
| `SHELL_BLING_SKIP_LAZYVIM=1`     | Don't clone LazyVim starter.                                                                                                                                            |
| `SHELL_BLING_SKIP_TOOLCHAINS=1`  | Skip `rustup`, `go` tarball, and `uv python install`. Falls back to distro-packaged `rustc`/`cargo`/`golang` where available. Saves ~900 MB of disk.                    |
| `SHELL_BLING_BYPASS_SIZE=1`      | Override the disk-space preflight (which needs ~2.6 GB on `$HOME`, or ~1 GB with `SHELL_BLING_SKIP_TOOLCHAINS=1`).                                                      |
| `SHELL_BLING_LIB_DIR=PATH`       | Override where `lib/` is loaded from.                                                                                                                                   |

### Saving disk space

The default install lands ~1.5 GB resident (Rust toolchain ~600 MB, Go toolchain ~270 MB, uv-managed Python ~30 MB, plus Neovim + LazyVim + apt packages + everything else). Peak during install is ~2.6 GB. If you're on a small VPS or container:

```sh
curl -fsSL https://raw.githubusercontent.com/hiAndrewQuinn/shell-bling-ubuntu/main/install.sh \
  | SHELL_BLING_SKIP_TOOLCHAINS=1 bash
```

You'll get the same shell + editor + CLI tools, plus whatever your distro packages for Rust/Go. On Debian 13 that's `rustc 1.85` and `go 1.24` — older than what `rustup`/`go.dev` provide, but real and usable. On Alpine/Arch you'll get current versions from the rolling repos. On older distros you may get nothing — in which case `cargo install` and `go install` won't work until you install a toolchain yourself.

## Hacking on it

```sh
pre-commit install
make lint           # shellcheck + shfmt + fish_indent + general hygiene
make test           # build + smoke-test every supported distro
make test-debian-13 # one distro
make dev            # interactive container after install
```

## License

[MIT](LICENSE).
