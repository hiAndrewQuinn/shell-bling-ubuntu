#!/bin/sh
# Post-install hook for fish (registered in lib/registry.sh).
# The engine has already installed /usr/local/bin/fish. fish 4.x ships a
# single statically-linked binary in its release tarball — no fish_indent,
# fish_key_reader, etc. (Those are dev tools; users who need them install
# the distro fish package on top.)
#
# The one thing we need to do: register /usr/local/bin/fish in /etc/shells
# so `chsh -s /usr/local/bin/fish` works in lib/pickers.sh.

fish_postinstall() {
  _fish=/usr/local/bin/fish
  [ -x "$_fish" ] || return 0
  if [ -w /etc/shells ] 2> /dev/null; then
    grep -qxF "$_fish" /etc/shells 2> /dev/null ||
      echo "$_fish" >> /etc/shells
  else
    grep -qxF "$_fish" /etc/shells 2> /dev/null ||
      printf '%s\n' "$_fish" | sudo_run tee -a /etc/shells > /dev/null
  fi
}
