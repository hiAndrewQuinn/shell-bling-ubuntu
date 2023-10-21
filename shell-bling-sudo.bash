#!/usr/bin/bash

# Part 1!
#
# Everything in this script is meant to be run FIRST,
# before we switch into the fish shell or out of root or anything.
# It should be installed with `curl wherever.bash | sudo bash`.

set -euo pipefail
# If not su, sudo, or root, exit.
if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root. Exiting."
	exit 1
fi

echo 'Installing all the "normal" nice things.'

# Get us any repositories we need to actually get this show on the road.
add-apt-repository -y ppa:neovim-ppa/unstable

apt update -y

apt install -y fish && apt -y autoremove && apt -y clean
apt install -y curl && apt -y autoremove && apt -y clean
apt install -y git && apt -y autoremove && apt -y clean
apt install -y micro && apt -y autoremove && apt -y clean
apt install -y ripgrep && apt -y autoremove && apt -y clean
apt install -y jq && apt -y autoremove && apt -y clean
apt install -y vim && apt -y autoremove && apt -y clean
apt install -y tmux && apt -y autoremove && apt -y clean
apt install -y neovim && apt -y autoremove && apt -y clean
apt install -y tree && apt -y autoremove && apt -y clean
apt install -y htop && apt -y autoremove && apt -y clean
apt install -y bat && apt -y autoremove && apt -y clean
apt install -y fd-find && apt -y autoremove && apt -y clean
apt install -y kitty && apt -y autoremove && apt -y clean
apt install -y lnav && apt -y autoremove && apt -y clean
apt install -y gron && apt -y autoremove && apt -y clean
apt install -y csvkit && apt -y autoremove && apt -y clean
apt install -y entr && apt -y autoremove && apt -y clean
apt install -y xclip && apt -y autoremove && apt -y clean
apt install -y gcc && apt -y autoremove && apt -y clean
apt install -y g++ && apt -y autoremove && apt -y clean
apt install -y make && apt -y autoremove && apt -y clean
apt install -y nodejs && apt -y autoremove && apt -y clean

snap install tldr \
	cheat \
	lsd || true

# Set kitty as our default terminal.
update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/kitty 50

echo -e "\033[1;33mPart 1 done.\033[0m"
echo -e ""

echo -e "\033[1;33mNext up: shell-bling-user.bash\033[0m"

exit 0
