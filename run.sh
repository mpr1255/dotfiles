#!/bin/bash
sudo chmod -x /etc/update-motd.d/*

# Update and upgrade
sudo apt update && sudo apt upgrade -y

# Install Zsh
sudo apt install zsh -y

# Install necessary packages for plugins and other functionality
sudo apt install git bat autojump python3-pip exa ripgrep zoxide fd-find autojump libfuse2 nnn -y

# Install Neovim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
chmod u+x nvim.appimage
sudo mv nvim.appimage /usr/local/bin/nvim


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

default_histfile="${HISTFILE:-$HOME/.zsh_history}"
export MCFLY_HISTFILE="${MCFLY_HISTFILE:-$default_histfile}"
if [[ ! -r "${MCFLY_HISTFILE}" ]]; then
  echo "McFly: ${MCFLY_HISTFILE} does not exist or is not readable. Please fix this or set MCFLY_HISTFILE to something else before using McFly."
  return 1
fi

# install ohmyzsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install zellij
if [ ! -f "/usr/local/bin/zellij" ]; then
    wget https://github.com/zellij-org/zellij/releases/download/v0.38.2/zellij-x86_64-unknown-linux-musl.tar.gz
    tar -xvf zellij-x86_64-unknown-linux-musl.tar.gz
    chmod +x zellij
    sudo mv zellij /usr/local/bin/
fi


# install fzf
if [ ! -d "~/.fzf" ]; then
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
	~/.fzf/install -y
fi

# Make sure the Neovim config directory exists
mkdir -p ~/.config/nvim

# Symlink init.lua for Neovim and .zshrc for Zsh
ln -sf ~/dotfiles/init.lua ~/.config/nvim/init.lua
ln -sf ~/dotfiles/.zshrc ~/.zshrc

# Reload the shell or print a message
if [ -z "$ZSH_CUSTOM" ]; then
  echo "Please restart your shell or run 'exec zsh -l' to apply changes."
else
  source ~/.zshrc
fi

if [ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

# Make Zsh default shell (moved to the end)
chsh -s $(which zsh)




ln -s $(which fdfind) ~/.local/bin/fd

