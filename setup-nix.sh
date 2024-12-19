#!/usr/bin/env bash
set -euo pipefail

HOMEDIR="/home/ubuntu"
CONFIG_DIR="$HOMEDIR/dotfiles/config"  # Where config files should end up

# Create required directories
mkdir -p "$HOMEDIR/.config/home-manager"
mkdir -p "$CONFIG_DIR"

# Copy files to their locations
echo "Setting up configuration files..."
cp "$(pwd)/home.nix" "$HOMEDIR/.config/home-manager/home.nix"

# Set up config directories
mkdir -p "$CONFIG_DIR/yazi"
mkdir -p "$CONFIG_DIR/zellij/layouts"

# Copy yazi configs
cp -r "$(pwd)/yazi/"* "$CONFIG_DIR/yazi/"

# Copy zellij configs
cp -r "$(pwd)/zellij/"* "$CONFIG_DIR/zellij/"

# Install Nix if not present
if ! command -v nix &> /dev/null; then
    echo "Installing Nix..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
    # Source nix
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# Install home-manager if not present
if ! command -v home-manager &> /dev/null; then
    echo "Installing home-manager..."
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
    nix-shell '<home-manager>' -A install
fi

if ! command -v tailscale &> /dev/null; then
    echo "Installing tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
fi

# Set up zsh in bashrc
if ! grep -q "exec.*zsh" "$HOMEDIR/.bashrc"; then
    echo 'exec $HOME/.nix-profile/bin/zsh' >> "$HOMEDIR/.bashrc"
fi

echo "Setup complete! You may need to restart your shell."
