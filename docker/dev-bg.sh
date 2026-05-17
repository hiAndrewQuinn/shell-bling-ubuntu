#!/bin/sh
# docker/dev-bg.sh — bring up a persistent shell-bling test container with
# an sshd running, so you can `ssh dev@localhost -p <port>` into it like
# it's a real machine.
#
# Why this exists vs `make dev`:
#   `make dev` is foreground-interactive (drop straight to a shell after
#   install). It's great for kicking the tires once. dev-bg is for poking
#   at the container repeatedly: it stays up, you can ssh in from another
#   terminal, scp files into it, do whatever.
#
# Usage:
#   sh docker/dev-bg.sh                          # interactive picker (fzf or numbered)
#   sh docker/dev-bg.sh ubuntu-24.04             # named distro, port 2222
#   sh docker/dev-bg.sh random                   # pick one at random
#   sh docker/dev-bg.sh debian-13 2244           # custom port
#   sh docker/dev-bg.sh --list                   # just print available distros
#   DEV_PUBKEY_GLOB='~/.ssh/work_*.pub' sh docker/dev-bg.sh
#
# Tear down with:
#   docker rm -f sbu-dev-<distro>
#   ( or `make dev-down DISTRO=<distro>` )

set -eu

DISTRO=${1:-}
PORT=${2:-2222}

# Distro list = every *.Dockerfile in docker/. Single source of truth so
# adding a new distro means dropping in docker/<name>.Dockerfile, nothing else.
_distro_list() {
  ls docker/*.Dockerfile 2> /dev/null | sed 's|docker/||;s|\.Dockerfile$||'
}

if [ "$DISTRO" = --list ]; then
  _distro_list
  exit 0
fi

if [ -z "$DISTRO" ]; then
  if command -v fzf > /dev/null 2>&1 && [ -t 0 ]; then
    DISTRO=$(_distro_list | fzf --prompt='distro> ' --height=40% --reverse) || exit 130
  else
    echo "available distros:"
    _distro_list | sed 's/^/  /'
    printf 'distro (or "random")> '
    read -r DISTRO
  fi
fi

if [ "$DISTRO" = random ]; then
  DISTRO=$(_distro_list | shuf | head -1)
  echo "==> random pick: $DISTRO"
fi

if [ -z "$DISTRO" ] || [ ! -f "docker/${DISTRO}.Dockerfile" ]; then
  echo "FATAL: no Dockerfile at docker/${DISTRO}.Dockerfile" >&2
  echo "       run with --list to see available distros." >&2
  exit 1
fi
IMG=shell-bling-test-${DISTRO}
NAME=sbu-dev-${DISTRO}

# Collect ssh pubkeys to inject. Default: every *.pub in ~/.ssh/.
# Override with DEV_PUBKEY_GLOB to pin to one file.
PUBKEY_GLOB=${DEV_PUBKEY_GLOB:-$HOME/.ssh/*.pub}
# shellcheck disable=SC2086  # word splitting on the glob is intentional
PUBKEYS=$(cat $PUBKEY_GLOB 2> /dev/null || true)
if [ -z "$PUBKEYS" ]; then
  echo "FATAL: no ssh pubkeys matched: $PUBKEY_GLOB" >&2
  echo "       set DEV_PUBKEY_GLOB or generate a keypair with ssh-keygen." >&2
  exit 1
fi

# Build the image (reuses make's image name so `make test-<distro>` still
# works against the same tag).
docker build -f "docker/${DISTRO}.Dockerfile" -t "${IMG}" . > /dev/null

# Idempotent: tear down any previous container of the same name.
docker rm -f "${NAME}" > /dev/null 2>&1 || true

# Launch detached. The inline script:
#   1. installs sshd via whichever pkg manager the distro carries
#   2. writes authorized_keys for the `dev` user
#   3. generates host keys, starts sshd
#   4. runs install.sh non-interactively (skips the fzf pickers that
#      would block stdin in a detached container)
#   5. prints the ready marker
#   6. tails /dev/null so the container doesn't exit
docker run -d -it --name "${NAME}" -p "${PORT}:22" \
  --entrypoint sh "${IMG}" \
  -c "
    set -eu
    cd /home/dev/shell-bling-ubuntu

    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update -q
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server
    elif command -v apk >/dev/null 2>&1; then
      sudo apk add --no-cache openssh
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y openssh-server
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -Sy --noconfirm openssh
    elif command -v zypper >/dev/null 2>&1; then
      sudo zypper -n install openssh
    else
      echo 'FATAL: no recognized package manager' >&2; exit 1
    fi

    mkdir -p /home/dev/.ssh
    chmod 700 /home/dev/.ssh
    cat > /home/dev/.ssh/authorized_keys <<KEYS
${PUBKEYS}
KEYS
    chmod 600 /home/dev/.ssh/authorized_keys

    sudo ssh-keygen -A
    sudo sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config 2>/dev/null || true
    sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config 2>/dev/null || true
    sudo mkdir -p /run/sshd
    sudo /usr/sbin/sshd

    SHELL_BLING_NONINTERACTIVE=1 sh install.sh

    printf '\n\033[1;32m==> dev container ready.\033[0m\n'
    tail -f /dev/null
  " > /dev/null

echo "==> container '${NAME}' starting (this includes a full install)..."
echo "    streaming logs — Ctrl+C to detach (container keeps running)..."
echo

# Stream until the ready marker, then exit (container stays up).
docker logs -f "${NAME}" 2>&1 | while IFS= read -r line; do
  printf '%s\n' "$line"
  case "$line" in
    *'dev container ready'*) break ;;
  esac
done

cat << EOF

==> '${NAME}' is up on port ${PORT}.

   ssh:    ssh -p ${PORT} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null dev@localhost
   exec:   docker exec -it ${NAME} fish        # or bash
   logs:   docker logs ${NAME}
   tear:   docker rm -f ${NAME}                # or: make dev-down DISTRO=${DISTRO}

EOF
