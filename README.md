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

Close and reopen your terminal again.

```fish
curl https://raw.githubusercontent.com/hiAndrewQuinn/shell-bling-ubuntu/main/shell-bling.fish | fish
```

Close and reopen your terminal one more time.

Then run `nvim`. You should see it pop up with all the neat little icons.

![image](https://github.com/hiAndrewQuinn/shell-bling-ubuntu/assets/53230903/5bb4eafb-b9cf-43ef-841e-23638074e1d5)
