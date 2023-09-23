#!/bin/bash
sudo chmod -x /etc/update-motd.d/*

# Update and upgrade
sudo apt update && sudo apt upgrade -y

# Install Zsh
sudo apt install zsh -y

# Install necessary packages for plugins and other functionality
sudo apt install fzf git bat autojump python3-pip exa ripgrep -y

# Install Neovim
sudo apt install neovim -y

# Install LazyGit
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin

# Install McFly
# Check if mcfly is already installed
if ! command -v mcfly &> /dev/null; then
	curl -LSfs https://raw.githubusercontent.com/cantino/mcfly/master/ci/install.sh | sh -s -- --git cantino/mcfly
    # Install mcfly here
fi

# Make sure the Neovim config directory exists
mkdir -p ~/.config/nvim

# Symlink init.lua for Neovim and .zshrc for Zsh
ln -sf ~/dotfiles/init.lua ~/.config/nvim/init.lua
ln -sf ~/dotfiles/.zshrc ~/.zshrc

# Make Zsh default shell (moved to the end)
chsh -s $(which zsh)
