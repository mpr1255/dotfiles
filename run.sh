#!/bin/bash

# Update and upgrade
sudo apt update && sudo apt upgrade -y

# Install Zsh
sudo apt install zsh -y

# Install necessary packages for plugins and other functionality
sudo apt install fzf git bat autojump python3-pip exa ripgrep -y

# Install Neovim
sudo apt install neovim -y

# Install LazyGit
sudo add-apt-repository ppa:lazygit-team/release -y
sudo apt-get update
sudo apt-get install lazygit -y

# Install McFly
wget https://github.com/cantino/mcfly/releases/download/v0.5.10/mcfly-v0.5.10-x86_64-unknown-linux-gnu.tar.gz
tar xzf mcfly-v0.5.10-x86_64-unknown-linux-gnu.tar.gz
sudo mv mcfly /usr/local/bin
rm mcfly-v0.5.10-x86_64-unknown-linux-gnu.tar.gz

# Clone your dotfiles (containing the .zshrc)
git clone https://github.com/mpr1255/dotfiles.git ~/dotfiles

# Install LazyVim
git clone https://github.com/klazy/lazyvim.git ~/.lazyvim
# Ensure Neovim config directory exists
mkdir -p ~/.config/nvim
ln -sf ~/.lazyvim/init.vim ~/.config/nvim/init.vim

# Symlink .zshrc
ln -sf ~/dotfiles/.zshrc ~/.zshrc

# Make Zsh default shell (moved to the end)
chsh -s $(which zsh)
