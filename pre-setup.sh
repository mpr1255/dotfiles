#!/usr/bin/env bash
set -euo pipefail

# Only create ubuntu user if it doesn't exist
if ! id "ubuntu" &>/dev/null; then
    useradd -m -s /bin/bash ubuntu
    usermod -aG sudo ubuntu
    mkdir -p /etc/sudoers.d
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu
    chmod 0440 /etc/sudoers.d/ubuntu
fi

# Set up SSH keys for ubuntu user
mkdir -p /home/ubuntu/.ssh
cp /root/.ssh/authorized_keys /home/ubuntu/.ssh/
chown -R ubuntu:ubuntu /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/authorized_keys

# Install packages
apt-get update
apt-get install -y curl git xz-utils systemd build-essential mosh

echo "Setup complete! You can now SSH in as the ubuntu user using your SSH key"