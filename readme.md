# Linux Dotfiles

Public dotfiles for setting up a new Linux system (e.g., Hetzner bare metal server). This repo contains sanitized configs without any API keys or personal information.

## Quick Setup Options

### Option 1: Simple Setup (if you already have a user account)

If you already have a non-root user account with sudo access:

```bash
# Clone and run setup
git clone https://github.com/mpr1255/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x *.sh
./setup.sh
exec $SHELL
```

### Option 2: Full Hetzner Server Setup (from root)

For a fresh Hetzner server where you need to create a user first:

#### 1. Pre-setup (as root)

Copy-paste the following to create ubuntu user and install basics:

```bash
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

echo "Setup complete! now dropping to ubuntu user"

exec su - ubuntu
```

#### 2. Main setup (as ubuntu user)

Clone this repo and run setup:

```bash
# Clone and run setup
git clone https://github.com/mpr1255/dotfiles.git dotfiles && cd dotfiles && chmod +x *.sh && ./setup.sh

# Reload shell
exec $SHELL

# Optional: Install tailscale
if ! command -v tailscale &> /dev/null; then
    echo "Installing tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
    sudo tailscale up --ssh
fi
```

## Contents

- `linux.zshrc` - Zsh configuration for Linux (no API keys)
- `.config/yazi/` - Yazi file manager configuration
- `.config/zellij/` - Zellij terminal multiplexer configuration
- `pre-setup.sh` - **[Run as root]** Creates user, sets up SSH (for fresh servers only)
- `setup.sh` - **[Run as user]** Installs all tools and configs (idempotent, safe to re-run)
- `refresh_from_mac.sh` - **[Run on Mac]** Updates repo from Mac configs (idempotent)

## Script Details

### setup.sh (Main Setup Script)
**Idempotent:** ✅ Yes, safe to run multiple times
**Runs as:** Regular user (needs sudo access)
**What it does:**
- Install zsh and set it as default shell
- Install modern CLI tools (eza, bat, fd, ripgrep, fzf, zoxide, etc.)
- Install yazi, zellij, starship, mcfly
- Set up zsh plugins
- Copy configs to `~/.zshrc`, `~/.config/yazi/`, `~/.config/zellij/`
- Create a `~/.secrets` file template for API keys

### pre-setup.sh (Initial Server Setup)
**Idempotent:** ✅ Yes, safe to run multiple times
**Runs as:** Root
**When to use:** Only needed on fresh Hetzner/bare metal servers where you need to create a non-root user
**What it does:**
- Creates `ubuntu` user with sudo access (skips if already exists)
- Copies SSH keys from root (skips if already exist)
- Installs basic packages: curl, git, build-essential, mosh
- Switches to ubuntu user

### refresh_from_mac.sh (Config Sync Script)
**Idempotent:** ✅ Yes, safe to run multiple times
**Runs as:** Regular user
**Runs on:** Mac only
**What it does:**
- Copies yazi and zellij configs from `~/.config/` to repo
- Automatically sanitizes configs for Linux:
  - Replaces Sublime Text paths with `$EDITOR`
  - Replaces `open` commands with `xdg-open`
  - Removes personal paths and info
- Ready to commit after running

## Updating Configs from Mac

When you update your configs on Mac and want to sync them to the repo:

```bash
cd ~/bin/dotfiles
./refresh_from_mac.sh
git add .
git commit -m "Update configs from Mac"
git push
```

## API Keys

The `linux.zshrc` file will source `~/.secrets` if it exists. Add your API keys there:

```bash
# ~/.secrets
export OPENAI_API_KEY="your-key-here"
export ANTHROPIC_API_KEY="your-key-here"
```

Make sure to set proper permissions:
```bash
chmod 600 ~/.secrets
```

## Installed Tools

### Package Manager Tools
- zsh, git, curl, wget, neovim
- ripgrep (rg), fd-find, bat, eza, fzf, zoxide
- sqlite3, 7zip, mpv, w3m

### Rust/Cargo Tools
- yazi (file manager)
- zellij (terminal multiplexer)
- ripgrep-all (rga)
- files-to-prompt

### Python/pipx Tools
- sqlite-utils
- uv (Python package manager)

### Other
- starship (prompt)
- mcfly (shell history)

### Zsh Plugins
- zsh-autosuggestions
- zsh-syntax-highlighting
- zsh-fzf-tab
- fzf-tab-completion

### Yazi Plugins
- zoxide, session, fr (fuzzy find), smart-enter, compress

**Note:** The setup script attempts to install yazi plugins using `ya pack`. If it fails, install them manually:
```bash
ya pack -a yazi-rs/plugins:zoxide
ya pack -a yazi-rs/plugins:session
ya pack -a yazi-rs/plugins:fr
ya pack -a yazi-rs/plugins:compress
ya pack -a ourongxing/smart-enter
```

## Directory Structure

```
.
├── readme.md
├── linux.zshrc              # Sanitized zshrc for Linux
├── setup.sh                 # Setup script for new systems
├── refresh_from_mac.sh      # Update repo from Mac
└── .config/
    ├── yazi/
    │   ├── init.lua
    │   ├── keymap.toml
    │   ├── yazi.toml
    │   └── theme.toml
    └── zellij/
        ├── config.kdl
        └── layouts/
            └── default.kdl
``` 