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

echo -e "\033[33mInstalling all the \"normal\" nice things.\033[0m"

# Get us any repositories we need to actually get this show on the road.
add-apt-repository -y ppa:neovim-ppa/unstable

apt update -y

apt install -y fish \
	curl \
	git \
	micro \
	ripgrep \
	jq \
	vim \
	tmux \
	neovim \
	tree \
	htop \
	bat \
	fd-find \
	kitty \
	lnav \
	gron \
	csvkit \
	entr \
	xclip \
	gcc \
        g++ \
	make \
        nodejs

snap install tldr \
	cheat \
	lsd || true

# Set kitty as our default terminal.
update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /usr/bin/kitty 50

echo -e "\033[1;33mScript 1 done! Next up: shell-bling-user.bash.\033[0m"
echo -e ""
echo -e "\033[33mClose your terminal, and use Ctrl+Alt+T. This time you should open into the Kitty terminal emulator, not the stock Ubuntu one.\033[0m"
echo -e ""
echo -e "\033[33m    curl https://raw.githubusercontent.com/hiAndrewQuinn/shell-bling-ubuntu/main/shell-bling-user.bash | bash\033[0m"
echo -e ""
echo -e "\033[33m    chsh -s $(which fish)\033[0m"
echo -e ""
echo -e "\033[1;33m(This is also on the README.md!)\033[0m"

exit 0
