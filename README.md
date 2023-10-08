# Shell Bling Ubuntu

A few shell scripts to get us some command-line niceties, for a fresh new Ubuntu installation.

## Quickstart

_From a brand spanking fresh new install of Ubuntu VM -- or even a Live USB!_

```bash
sudo apt install -y curl   # well it can't all be in a script!
curl https://raw.githubusercontent.com/hiAndrewQuinn/shell-bling-ubuntu/main/shell-bling-sudo.bash | sudo bash
```

Close your terminal, and use `Ctrl+Alt+T`. This time you should open into the Kitty terminal emulator, not the stock Ubuntu one.

```bash
curl https://raw.githubusercontent.com/hiAndrewQuinn/shell-bling-ubuntu/main/shell-bling-user.bash | bash

chsh -s $(which fish)
````

Log out, and log in again. 

```fish
curl https://raw.githubusercontent.com/hiAndrewQuinn/shell-bling-ubuntu/main/shell-bling.fish | fish
```
