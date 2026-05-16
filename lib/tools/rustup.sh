#!/bin/sh
# Install the Rust toolchain via rustup. Lands cargo + rustc in ~/.cargo/bin
# for the *invoking* user (NOT root) — that's where rustup wants to live and
# where shells expect to find it. PATH wiring lives in lib/fish_setup.sh.

install_rustup() {
  has_cmd rustup && return 0
  case "$DISTRO" in
    macos)
      brew install rustup-init && rustup-init -y \
        --default-toolchain stable --profile minimal --no-modify-path \
        > /dev/null
      return $?
      ;;
  esac

  # If we're already root (Docker test path), still install for the user that
  # will be using the shell — but in our flows root *is* the test user.
  # rustup writes to $HOME/.cargo, so $HOME has to be the right user.
  log "Installing Rust toolchain (rustup, minimal profile, stable)"
  if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    -o /tmp/rustup-init.sh; then
    warn "rustup install script download failed; skipping"
    return 0
  fi
  RUSTUP_HOME="${HOME}/.rustup" CARGO_HOME="${HOME}/.cargo" \
    sh /tmp/rustup-init.sh -y \
    --default-toolchain stable --profile minimal --no-modify-path \
    > /dev/null
  _rc=$?
  rm -f /tmp/rustup-init.sh
  return "$_rc"
}
