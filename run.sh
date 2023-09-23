#!/bin/bash

# Permissions
sudo chmod -x /etc/update-motd.d/*

# Update and upgrade
sudo apt update && sudo apt upgrade -y

# Install Zsh
sudo apt install zsh -y

# Install packages
sudo apt install git bat autojump python3-pip exa ripgrep zoxide fd-find autojump libfuse2 nnn   trash-cli -y

# Install Neovim
if [ ! -f "/usr/local/bin/nvim" ]; then
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
    chmod u+x nvim.appimage
    sudo mv nvim.appimage /usr/local/bin/nvim
fi

# Install McFly
if ! command -v mcfly &> /dev/null; then
    curl -LSfs https://raw.githubusercontent.com/cantino/mcfly/master/ci/install.sh | sh -s -- --git cantino/mcfly
fi

# Install Oh My Zsh only if it isn't installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Install Zellij
if [ ! -f "/usr/local/bin/zellij" ]; then
    wget https://github.com/zellij-org/zellij/releases/download/v0.38.2/zellij-x86_64-unknown-linux-musl.tar.gz
    tar -xvf zellij-x86_64-unknown-linux-musl.tar.gz
    chmod +x zellij
    sudo mv zellij /usr/local/bin/
fi

# Install fzf
if [ ! -d "$HOME/.fzf" ]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
fi

# Ensure ~/.config/nvim exists
mkdir -p ~/.config/nvim

# Symlink Neovim and Zsh configs
ln -sf ~/dotfiles/init.lua ~/.config/nvim/init.lua
ln -sf ~/dotfiles/.zshrc ~/.zshrc

# Load new shell settings
source ~/.zshrc

# Make Zsh the default shell
chsh -s $(which zsh)

# Link fd (if not linked)
if [ ! -L "$HOME/.local/bin/fd" ]; then
    mkdir -p ~/.local/bin
    ln -s $(which fdfind) ~/.local/bin/fd
fi


default_histfile="${HISTFILE:-$HOME/.zsh_history}"
export MCFLY_HISTFILE="${MCFLY_HISTFILE:-$default_histfile}"
if [[ ! -r "${MCFLY_HISTFILE}" ]]; then
  echo "McFly: ${MCFLY_HISTFILE} does not exist or is not readable. Please fix this or set MCFLY_HISTFILE to something else before using McFly."
  return 1
fi