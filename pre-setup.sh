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

# Set up SSH keys for ubuntu user (only if not already set up)
mkdir -p /home/ubuntu/.ssh
if [ ! -f /home/ubuntu/.ssh/authorized_keys ] && [ -f /root/.ssh/authorized_keys ]; then
    cp /root/.ssh/authorized_keys /home/ubuntu/.ssh/
    echo "SSH keys copied from root"
fi
chown -R ubuntu:ubuntu /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/authorized_keys 2>/dev/null || true

# Install packages
apt-get update
apt-get install -y curl git xz-utils systemd build-essential mosh

echo "Setup complete! now dropping to ubuntu user"

exec su - ubuntu