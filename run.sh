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
curl -LSfs https://raw.githubusercontent.com/cantino/mcfly/master/ci/install.sh | sh -s -- --git cantino/mcfly

# Clone your dotfiles (containing the .zshrc)
git clone https://github.com/mpr1255/dotfiles.git ~/dotfiles

# Install Lazy.nvim and configure it
nvim --headless -c "lua <<EOF
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
EOF
"

# Another command to run setup (if you want)
nvim --headless -c "lua require('lazy').setup({'folke/which-key.nvim', {'folke/neoconf.nvim', cmd = 'Neoconf'}, 'folke/neodev.nvim'})"






# Ensure Neovim config directory exists
mkdir -p ~/.config/nvim
ln -sf ~/.lazyvim/init.vim ~/.config/nvim/init.vim

# Symlink .zshrc
ln -sf ~/dotfiles/.zshrc ~/.zshrc

# Make Zsh default shell (moved to the end)
chsh -s $(which zsh)
