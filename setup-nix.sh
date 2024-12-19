#!/usr/bin/env bash
set -euo pipefail

# First create ubuntu user if it doesn't exist
if ! id "ubuntu" &>/dev/null; then
    echo "Creating ubuntu user..."
    useradd -m -s /bin/bash ubuntu
    # Add to sudo group
    usermod -aG sudo ubuntu
    # Set up sudo without password for ubuntu user
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu
    chmod 0440 /etc/sudoers.d/ubuntu
fi

# Install essential dependencies as root
apt-get update && apt-get install -y curl git xz-utils systemd build-essential

# Create directory structure for ubuntu user
HOMEDIR="/home/ubuntu"
mkdir -p "$HOMEDIR/.config/home-manager"
mkdir -p "$HOMEDIR/dotfiles/config"
chown -R ubuntu:ubuntu "$HOMEDIR"

# Define the function to run as ubuntu user
setup_nix() {
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

    # Set up zsh in bashrc if not already there
    if ! grep -q "exec.*zsh" "$HOMEDIR/.bashrc"; then
        echo 'exec $HOME/.nix-profile/bin/zsh' >> "$HOMEDIR/.bashrc"
    fi
}

# Run the setup function as ubuntu user
echo "Switching to ubuntu user and running setup..."
sudo -u ubuntu bash -c "$(declare -f setup_nix); setup_nix"

echo "Setup complete. Previous configuration backed up as home.nix.bak if it existed."
echo "Home directory set to: $HOMEDIR"
echo "Username set to: ubuntu"
echo "exec zsh added to ~/.bashrc"
