#!/usr/bin/env bash
set -euo pipefail

# Determine username and home directory
USERNAME="${1:-$(whoami)}"
if [ "$USERNAME" = "root" ]; then
    HOMEDIR="/root"
else
    HOMEDIR="/home/$USERNAME"
fi

# Create required directories
mkdir -p "$HOMEDIR/.config/home-manager"
mkdir -p "$HOMEDIR/dotfiles/config"

# Backup existing configuration if present
if [ -f "$HOMEDIR/.config/home-manager/home.nix" ]; then
    mv "$HOMEDIR/.config/home-manager/home.nix" "$HOMEDIR/.config/home-manager/home.nix.bak"
fi

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

# Download configuration file
echo "Downloading home.nix configuration..."
curl -sSL https://raw.githubusercontent.com/mpr1255/dotfiles/refs/heads/master/home.nix \
    -o "$HOMEDIR/.config/home-manager/home.nix"

echo 'exec /root/.nix-profile/bin/zsh' >> ~/.bashrc
echo "Setup complete. Previous configuration backed up as home.nix.bak if it existed."
echo "Home directory set to: $HOMEDIR"
echo "Username set to: $USERNAME"
echo "exec /root/.nix-profile/bin/zsh added to ~/.bashrc"
