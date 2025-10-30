#!/bin/bash
# Hetzner Bootstrap Script
# Copy-paste this into a fresh Hetzner rescue environment as root
# It will set up RAID-0, install Ubuntu, create ubuntu user, and install dotfiles

set -e

echo "=========================================="
echo "Hetzner Server Bootstrap"
echo "=========================================="

# Check if we're in rescue mode or installed system
if [ -f /etc/hetzner-rescue ]; then
    echo "Running in Hetzner Rescue mode - will install system"
    IN_RESCUE=1
else
    echo "Running in installed system - will configure"
    IN_RESCUE=0
fi

if [ "$IN_RESCUE" -eq 1 ]; then
    echo ""
    echo "STEP 1: Installing Ubuntu with RAID-0"
    echo "=========================================="

    # Create installimage config
    cat > /tmp/installimage-config << 'EOF'
DRIVE1 /dev/nvme0n1
DRIVE2 /dev/nvme1n1
SWRAID 1
SWRAIDLEVEL 0
BOOTLOADER grub
HOSTNAME Ubuntu-2404-noble-amd64-base
PART /boot ext3 512M
PART lvm vg0 all
LV vg0 root / ext4 100G
LV vg0 home /home ext4 50G
IMAGE /root/.oldroot/nfs/install/../images/Ubuntu-2404-noble-amd64-base.tar.gz
EOF

    # Run installimage with config
    echo "Running installimage..."
    installimage -a -c /tmp/installimage-config

    # Create post-install script that will run on first boot
    echo "Creating post-install setup script..."

    cat > /mnt/root/first-boot-setup.sh << 'FIRSTBOOT'
#!/bin/bash
set -e

echo "=========================================="
echo "First Boot Setup"
echo "=========================================="

# Install sudo
echo "Installing sudo..."
apt update
apt install -y sudo curl git

# Create ubuntu user
echo "Creating ubuntu user..."
if ! id ubuntu &>/dev/null; then
    useradd -m -s /bin/bash ubuntu
fi

# Set up SSH keys
echo "Setting up SSH keys..."
mkdir -p /home/ubuntu/.ssh
if [ -f /root/.ssh/authorized_keys ]; then
    cp /root/.ssh/authorized_keys /home/ubuntu/.ssh/authorized_keys
    chown -R ubuntu:ubuntu /home/ubuntu/.ssh
    chmod 700 /home/ubuntu/.ssh
    chmod 600 /home/ubuntu/.ssh/authorized_keys
fi

# Set up sudo
echo "Configuring sudo..."
usermod -aG sudo ubuntu
echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-ubuntu
chmod 440 /etc/sudoers.d/90-ubuntu

# Install Tailscale (optional - uncomment if you want it)
# echo "Installing Tailscale..."
# curl -fsSL https://tailscale.com/install.sh | sh

# Clone dotfiles and run setup as ubuntu user
echo "Setting up dotfiles..."
sudo -u ubuntu bash << 'USERSCRIPT'
cd ~
if [ ! -d ~/dotfiles ]; then
    git clone https://github.com/mpr1255/dotfiles.git ~/dotfiles
    cd ~/dotfiles
    chmod +x *.sh
    ./setup.sh
fi
USERSCRIPT

# Remove this script from rc.local
sed -i '/first-boot-setup.sh/d' /etc/rc.local

echo ""
echo "=========================================="
echo "Setup complete!"
echo "=========================================="
echo "You can now:"
echo "  - SSH as ubuntu@your-server-ip"
echo "  - Use sudo without password"
echo "  - All dotfiles are installed"
echo ""

# Self-delete
rm -f /root/first-boot-setup.sh

FIRSTBOOT

    chmod +x /mnt/root/first-boot-setup.sh

    # Add to rc.local to run on first boot
    if [ ! -f /mnt/etc/rc.local ]; then
        cat > /mnt/etc/rc.local << 'RCLOCAL'
#!/bin/bash
/root/first-boot-setup.sh >> /var/log/first-boot-setup.log 2>&1
exit 0
RCLOCAL
        chmod +x /mnt/etc/rc.local
    else
        # Insert before exit 0
        sed -i '/^exit 0/i /root/first-boot-setup.sh >> /var/log/first-boot-setup.log 2>&1' /mnt/etc/rc.local
    fi

    echo ""
    echo "=========================================="
    echo "Installation complete!"
    echo "=========================================="
    echo ""
    echo "The system will now reboot and automatically:"
    echo "  1. Create ubuntu user with your SSH key"
    echo "  2. Set up sudo"
    echo "  3. Clone and install dotfiles"
    echo ""
    echo "After reboot, SSH as: ubuntu@your-server-ip"
    echo ""
    read -p "Press Enter to reboot now, or Ctrl+C to cancel..."
    reboot

else
    # Running in installed system - this is the fallback if first boot didn't work
    echo ""
    echo "STEP 2: Post-install configuration"
    echo "=========================================="

    # Install sudo if not present
    if ! command -v sudo &> /dev/null; then
        echo "Installing sudo..."
        apt update
        apt install -y sudo curl git
    fi

    # Create ubuntu user if not exists
    if ! id ubuntu &>/dev/null; then
        echo "Creating ubuntu user..."
        useradd -m -s /bin/bash ubuntu
    fi

    # Set up SSH keys
    echo "Setting up SSH keys..."
    mkdir -p /home/ubuntu/.ssh
    if [ -f /root/.ssh/authorized_keys ]; then
        cp /root/.ssh/authorized_keys /home/ubuntu/.ssh/authorized_keys
        chown -R ubuntu:ubuntu /home/ubuntu/.ssh
        chmod 700 /home/ubuntu/.ssh
        chmod 600 /home/ubuntu/.ssh/authorized_keys
    fi

    # Set up sudo
    echo "Configuring sudo..."
    usermod -aG sudo ubuntu
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-ubuntu
    chmod 440 /etc/sudoers.d/90-ubuntu

    # Install dotfiles as ubuntu user
    echo "Installing dotfiles..."
    sudo -u ubuntu bash << 'USERSCRIPT'
cd ~
if [ ! -d ~/dotfiles ]; then
    git clone https://github.com/mpr1255/dotfiles.git ~/dotfiles
    cd ~/dotfiles
    chmod +x *.sh
    ./setup.sh
fi
USERSCRIPT

    echo ""
    echo "=========================================="
    echo "Setup complete!"
    echo "=========================================="
    echo ""
    echo "You can now:"
    echo "  - SSH as ubuntu@your-server-ip"
    echo "  - Use sudo without password"
    echo "  - All dotfiles are installed"
    echo ""
fi
