# Shell Bling Ubuntu

A curated set of command-line niceties for a fresh Ubuntu, Debian, Fedora, or
macOS install. One command, sudo password once, fzf picker at the end.

📄 Landing page: **<https://hiandrewquinn.github.io/shell-bling-ubuntu/>**

## Quickstart

```sh
wget -qO- https://raw.githubusercontent.com/hiAndrewQuinn/shell-bling-ubuntu/main/install.sh | sh
```

`wget` is preferred because it ships in more base images than `curl` does —
fresh Debian 13, for example, has `wget` but not `curl`. If you already have
`curl`, you can use that instead:

```sh
curl -fsSL https://raw.githubusercontent.com/hiAndrewQuinn/shell-bling-ubuntu/main/install.sh | sh
```

Either way the script installs `curl` itself before it needs to fetch anything
else, so they're equivalent once it's running.

That's it. The script will:

1. Detect your platform.
2. Ask for your sudo password once (and keep the timestamp alive in the
   background).
3. Install everything silently.
4. Open one `fzf` picker for your default editor (`nvim` / `vim` / `hx` /
   `micro`). `fish` becomes your login shell automatically.
5. Print a friendly recap.

Log out of your desktop session and back in (or reboot) when it finishes —
that's how `$SHELL` and the new `x-terminal-emulator` default actually take
effect. Just reopening a terminal usually isn't enough.

## Philosophy: zero configuration files

**Shell Bling never drops a dotfile in your home directory.** No `.vimrc`, no
`.tmux.conf`, no opinionated `config.fish`. The one exception is the optional
LazyVim starter, which is its own scaffolded thing you can ignore or replace.

Where possible we ship zero-config tools that just work — `fzf`, `starship`,
`zoxide`, `bat`, `eza`, `lsd`, `helix`, `micro`. Where there's a real choice
to make, we ship multiple variants side-by-side and let you pick: `nvim` /
`vim` / `hx` / `micro` for editors, `lsd` + `eza` for modern `ls`, `xclip` +
`wl-clipboard` for the X11/Wayland split. You configure your shell on your
own time, in your own way.

## Supported platforms

Shell Bling runs in a Docker matrix of **30 distros across 7 package-manager
families** on every change. Today the matrix is amd64-only; arm64 coverage
is in flight. macOS is supported (via Homebrew) but not Docker-tested.

### Tier 1 — fully supported

All 23 tools install at pinned version. Smoke test PASS without softening.

**Testing:** ✓ Docker matrix · ✓ automated VM matrix · ✓ manual VM end-to-end

| Distro                                 | Notes                       |
| -------------------------------------- | --------------------------- |
| Ubuntu 22.04, 24.04, 26.04             | jammy, noble, resolute      |
| Debian 12, 13                          | bookworm, trixie            |
| Kali Linux rolling                     | tracks Debian sid           |

### Tier 2 — file issues if anything breaks

All 23 tools land cleanly; either modern enough not to need any softening,
or quirks we haven't fully characterized:

**Testing:** ✓ Docker matrix · ~ automated VM matrix (in progress) · ✗ manual VM

| Distro                                 | Pkg manager      |
| -------------------------------------- | ---------------- |
| Fedora 40, 41, 42, 43, 44              | dnf              |
| Rocky Linux 9, 10                      | dnf + EPEL       |
| AlmaLinux 9, 10                        | dnf + EPEL       |
| CentOS Stream 9, 10                    | dnf + EPEL       |
| Amazon Linux 2023                      | dnf (no EPEL)    |
| Arch Linux                             | pacman           |
| Manjaro                                | pacman           |
| Alpine Linux                           | apk (musl)       |
| openSUSE Tumbleweed                    | zypper           |
| Void Linux                             | xbps             |
| macOS (Intel + Apple Silicon)          | Homebrew         |
| WSL2 (Ubuntu/Debian under Windows)     | inherits parent  |

### Tier 3 — degraded with explicit Known Limitations

Install succeeds; the engine prints a "Known limitations on this platform"
notice explaining which specific tools couldn't land and why. Almost always
it's `helix` and `neovim` — their upstream binaries require glibc 2.34+ and
ship no musl variant, so older distros either fall through to an older
distro-packaged `nvim` (which works fine) or end up genuinely missing `hx`.

If you hit a new wrinkle on one of these distros, expect that fixing it
may require softening the install scripts — that's the contract of Tier 3.

**Testing:** ✓ Docker matrix · ✗ automated VM · ✗ manual VM

| Distro                                 | Tools landed | What's degraded |
| -------------------------------------- | :----------: | --------------- |
| openSUSE Leap 15.6                     | 23/23        | None — `qsv` routes to its musl variant transparently (glibc 2.38) |
| Debian 11 bullseye                     | 21/23        | `helix`, `neovim` (glibc 2.31; nvim distro fallback installs 0.4.4) |
| Ubuntu 20.04 focal                     | 21/23        | `helix`, `neovim` (glibc 2.31; same shape as Debian 11) |
| Rocky Linux 8, AlmaLinux 8             | 21/23        | `helix`, `neovim` (glibc 2.28; EPEL 8 has nvim 0.8.0) |
| Amazon Linux 2                         | 21/23        | `helix`, `neovim` (glibc 2.26; yum-era) |
| CentOS 7                               | 21/23        | `helix`, `neovim` (glibc 2.17; yum-era; Dockerfile points yum at vault.centos.org since the base mirror was decommissioned post-EOL) |

For the legacy-glibc distros (anything in the table above with glibc < 2.28),
five Rust binaries — `bat`, `fd`, `eza`, `lsd`, `starship` — automatically
route to their musl variants via the registry's `GLIBC_MIN` fallback. You'll
get the same version of those tools as on a modern distro, just statically
linked against musl.

### What we don't test

This isn't a "we couldn't be bothered" list — these are deliberately out of
scope, mostly because they're architectural mismatches with shell-bling's
"drop pinned binaries into `/usr/local/bin`" model:

- **NixOS, GuixSD** — functional package management. Tools should be in
  `/nix/store` with proper Nix expressions, not bolted into `/usr/local/bin`.
- **CoreOS, Flatcar, Bottlerocket, ChromeOS** — immutable OSes; `/usr` is
  read-only.
- **The BSDs (FreeBSD, OpenBSD, NetBSD)** — different OS family; most of our
  pinned upstream binaries don't have BSD variants.
- **SLES 15** — official Docker images require a SUSE subscription.
  openSUSE Leap 15.6 (which we DO test) is the open-source counterpart.
- **Linux Mint LMDE, Pop!_OS, EndeavourOS, Parrot OS** — covered
  transitively by their parent distros (Debian / Ubuntu / Arch). Should
  Just Work, but we don't run them through CI.

Tier 1 platforms are tested in CI on every commit, plus through automated
and manual VM cycles. Tier 2 and Tier 3 are best-effort — please file
issues if you hit something the Known Limitations notice doesn't cover.

## Try before you install

```sh
git clone https://github.com/hiAndrewQuinn/shell-bling-ubuntu
cd shell-bling-ubuntu
make dev DISTRO=ubuntu-24.04   # or debian-13, ubuntu-22.04, etc.
```

This drops you into an interactive shell inside a fresh container after the
installer runs. Great for kicking the tires.

### Poking at it like a real machine (SSH into the container)

If you want the container to stick around — to attach from a second terminal,
`scp` files in/out, or just have it feel like a remote machine:

```sh
make dev-bg DISTRO=debian-13          # also installs sshd, port 2222
# wait for the "dev container ready" marker, then:
ssh -p 2222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null dev@localhost
# or attach in-place:
docker exec -it sbu-dev-debian-13 fish
# tear down when done:
make dev-down DISTRO=debian-13
```

Don't want to remember the distro string? Skip `DISTRO=` and the script
pops an fzf picker (or falls back to a numbered prompt) listing every
`docker/*.Dockerfile` it finds:

```sh
sh docker/dev-bg.sh                   # interactive picker
sh docker/dev-bg.sh random            # roll one at random
sh docker/dev-bg.sh --list            # just print available distros
```

`dev-bg` copies every `~/.ssh/*.pub` you have into the container's
`authorized_keys` so any of your existing keys will get you in.
Override the port with `DEV_PORT=2244`, or pin to one specific key
with `DEV_PUBKEY_GLOB='~/.ssh/work_*.pub'`.

Differences from `make dev`:

| | `make dev` | `make dev-bg` |
|---|---|---|
| install runs | yes | yes (non-interactively) |
| stays up after install | no (drops to foreground shell, exits on logout) | yes (until `make dev-down`) |
| sshd | no | yes, port `$DEV_PORT` (default 2222) |
| fzf pickers | yes (real tty) | no (skipped via `SHELL_BLING_NONINTERACTIVE=1`) |
| best for | first-time "look around" | repeated experimentation |

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
- **[xclip](https://github.com/astrand/xclip)** + **[wl-clipboard](https://github.com/bugaevc/wl-clipboard)** — pipe to/from the system clipboard. Both installed so the same scripts work on X11 *and* Wayland (each one no-ops on the other's display server).

</details>

<details>
<summary><strong>Help & cheatsheets</strong></summary>

- **[tldr](https://tldr.sh/)** (the [tealdeer](https://github.com/tealdeer-rs/tealdeer) Rust client) — simplified man pages.
- **[cheat](https://github.com/cheat/cheat)** — interactive cheatsheets.

</details>

<details>
<summary><strong>File & directory tools</strong></summary>

- **[zoxide](https://github.com/ajeetdsouza/zoxide)** — smarter `cd` that learns your habits.
- **[lsd](https://github.com/lsd-rs/lsd)** + **[eza](https://eza.rocks/)** — modern `ls` with icons & colors.
- **[tree](http://mama.indstate.edu/users/ice/tree/)** — directories as a tree.
- **[rsync](https://rsync.samba.org/)** — smart file copy/sync, locally or over ssh.

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
<summary><strong>JSON</strong></summary>

- **[jq](https://jqlang.org/)** — the de-facto JSON query language. Filter, reshape, project. Powerful, opinionated, with its own little DSL to learn.
- **[gron](https://github.com/tomnomnom/gron)** — makes JSON greppable. Flattens any blob into one `foo.bar[3].baz = "..."` line per leaf so you can `rg` / `grep` / `fzf` through it with tools you already know. Round-trips back to JSON with `gron -u`. A very different beast from `jq`.

</details>

<details>
<summary><strong>Other data wrangling</strong></summary>

- **[qsv](https://github.com/dathere/qsv)** — fast CSV scalpels (sub-commands for select, search, stats, join, frequency, etc.).
- **[sqlite3](https://sqlite.org/)** — the world's most-used database, on tap for any "I need a real query for ten minutes" moment.

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

| Var                              | Effect                                                                                                              |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `SHELL_BLING_NONINTERACTIVE=1`   | Skip the editor fzf picker; default editor=`nvim`.                                                                  |
| `SHELL_BLING_SKIP_LAZYVIM=1`     | Don't clone LazyVim starter.                                                                                        |
| `SHELL_BLING_BYPASS_SIZE=1`      | Override the disk-space preflight (which needs ~1 GB free on `$HOME`).                                              |
| `SHELL_BLING_LIB_DIR=PATH`       | Override where `lib/` is loaded from.                                                                               |

### Footprint

Resident install is ~600 MB (Neovim + LazyVim + apt packages + the registry-installed static binaries). shell-bling no longer installs language toolchains — if you want Rust, Go, or uv, install them yourself from their official sources after shell-bling runs. The principle: shell-bling is a productive-shell installer, not a language-toolchain manager.

## Hacking on it

```sh
pre-commit install
make lint           # shellcheck + shfmt + fish_indent + general hygiene
make test           # build + smoke-test every supported distro
make test-debian-13 # one distro
make dev            # interactive container after install
```

## License

[The Unlicense](LICENSE) — released into the public domain. Do what you
want with it.
