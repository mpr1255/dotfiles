#!/usr/bin/env bash
set -euo pipefail

# First create ubuntu user if it doesn't exist
if ! id "ubuntu" &>/dev/null; then
    echo "Creating ubuntu user..."
    useradd -m -s /bin/bash ubuntu
    usermod -aG sudo ubuntu
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu
    chmod 0440 /etc/sudoers.d/ubuntu
fi

# Install essential dependencies as root
apt-get update && apt-get install -y curl git xz-utils systemd build-essential mosh

echo "Basic system setup complete. Now run setup-nix.sh as ubuntu user."