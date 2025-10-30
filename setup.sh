#!/bin/bash
# setup.sh
# Sets up a new Linux system with dotfiles and required software
# Idempotent - can be run multiple times safely

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "======================================"
echo "Setting up Linux dotfiles environment"
echo "======================================"

# Set up passwordless sudo if not already configured
echo "Checking sudo configuration..."
if ! sudo -n true 2>/dev/null; then
    echo "Passwordless sudo not configured. Setting it up now..."
    echo "You may be prompted for your password once."

    # This will prompt for password once, then set up NOPASSWD
    echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/90-$USER > /dev/null
    sudo chmod 440 /etc/sudoers.d/90-$USER

    # Verify it worked
    if ! sudo -n true 2>/dev/null; then
        echo "Error: Failed to set up passwordless sudo."
        echo "Please ensure you're in the sudo group:"
        echo "  sudo usermod -aG sudo $USER"
        echo "Then log out and back in."
        exit 1
    fi

    echo "Passwordless sudo configured successfully."
fi

# Refresh sudo timestamp to avoid prompts during installation
sudo -v

# Detect package manager
if command -v apt-get &> /dev/null; then
    PKG_MANAGER="apt"
    INSTALL_CMD="sudo apt-get install -y"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    INSTALL_CMD="sudo dnf install -y"
elif command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
    INSTALL_CMD="sudo pacman -S --noconfirm"
else
    echo "Error: No supported package manager found (apt, dnf, or pacman)"
    exit 1
fi

echo "Detected package manager: $PKG_MANAGER"

# Update package lists
echo "Updating package lists..."
if [ "$PKG_MANAGER" = "apt" ]; then
    sudo apt-get update
elif [ "$PKG_MANAGER" = "dnf" ]; then
    sudo dnf check-update || true
fi

# Install basic tools
echo "Installing basic tools..."
BASIC_TOOLS=(
    "zsh"
    "git"
    "curl"
    "wget"
    "build-essential"  # apt-specific, need to handle per distro
)

# Install tools (handling package name differences)
for tool in zsh git curl wget; do
    if ! command -v $tool &> /dev/null; then
        echo "Installing $tool..."
        $INSTALL_CMD $tool
    else
        echo "$tool already installed"
    fi
done

# Install build-essential or equivalent
if [ "$PKG_MANAGER" = "apt" ]; then
    $INSTALL_CMD build-essential
elif [ "$PKG_MANAGER" = "dnf" ]; then
    $INSTALL_CMD gcc gcc-c++ make
elif [ "$PKG_MANAGER" = "pacman" ]; then
    $INSTALL_CMD base-devel
fi

# Install modern CLI tools
echo "Installing modern CLI tools..."
TOOLS=(
    "fd-find"      # apt: fd-find, dnf/pacman: fd
    "ripgrep"      # rg
    "bat"
    "eza"          # modern ls
    "zoxide"       # smart cd
    "fzf"
    "neovim"
    "sqlite3"
    "7zip"
    "mpv"
    "w3m"
)

# Tool name mapping for different package managers
declare -A TOOL_NAMES
if [ "$PKG_MANAGER" = "apt" ]; then
    TOOL_NAMES["fd"]="fd-find"
else
    TOOL_NAMES["fd"]="fd"
fi

# Install tools with error handling
for tool in ripgrep bat eza zoxide fzf neovim sqlite3 mpv w3m; do
    if ! command -v $tool &> /dev/null; then
        echo "Installing $tool..."
        $INSTALL_CMD $tool 2>/dev/null || echo "Warning: Could not install $tool (may need manual installation)"
    else
        echo "$tool already installed"
    fi
done

# Install fd-find (special case)
if ! command -v fd &> /dev/null && ! command -v fdfind &> /dev/null; then
    echo "Installing fd..."
    if [ "$PKG_MANAGER" = "apt" ]; then
        $INSTALL_CMD fd-find
        # Create symlink for apt's fd-find -> fd
        if [ ! -L "$HOME/.local/bin/fd" ]; then
            mkdir -p "$HOME/.local/bin"
            ln -s "$(which fdfind)" "$HOME/.local/bin/fd" 2>/dev/null || true
        fi
    else
        $INSTALL_CMD fd
    fi
else
    echo "fd already installed"
fi

# Install Rust (needed for cargo tools)
if ! command -v cargo &> /dev/null; then
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "Rust already installed"
fi

# Install uv (Python package manager)
if ! command -v uv &> /dev/null; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
else
    echo "uv already installed"
fi

# Install starship prompt via cargo (avoids sudo prompts)
if ! command -v starship &> /dev/null; then
    echo "Installing starship..."
    cargo install starship --locked 2>/dev/null || echo "Warning: Could not install starship via cargo"
else
    echo "starship already installed"
fi

# Install mcfly via cargo (avoids sudo prompts)
if ! command -v mcfly &> /dev/null; then
    echo "Installing mcfly..."
    cargo install mcfly --locked 2>/dev/null || echo "Warning: Could not install mcfly via cargo"
else
    echo "mcfly already installed"
fi

# Install yazi
if ! command -v yazi &> /dev/null; then
    echo "Installing yazi..."
    cargo install --locked yazi-fm yazi-cli
else
    echo "yazi already installed"
fi

# Install zellij
if ! command -v zellij &> /dev/null; then
    echo "Installing zellij..."
    cargo install --locked zellij
else
    echo "zellij already installed"
fi

# Install additional tools via cargo
echo "Installing additional cargo tools..."
CARGO_TOOLS=(
    "ripgrep-all"  # rga
    "files-to-prompt"
)

for tool in "${CARGO_TOOLS[@]}"; do
    TOOL_BIN="${tool%%-*}"  # Get first part of name
    if ! command -v $TOOL_BIN &> /dev/null; then
        echo "Installing $tool..."
        cargo install --locked $tool 2>/dev/null || echo "Warning: Could not install $tool"
    else
        echo "$tool already installed"
    fi
done

# Install sqlite-utils via pipx
if ! command -v pipx &> /dev/null; then
    echo "Installing pipx..."
    $INSTALL_CMD python3-pip python3-venv
    python3 -m pip install --user pipx
    python3 -m pipx ensurepath
fi

if ! command -v sqlite-utils &> /dev/null; then
    echo "Installing sqlite-utils..."
    pipx install sqlite-utils
else
    echo "sqlite-utils already installed"
fi

# Set up zsh plugins
echo "Setting up zsh plugins..."
ZSH_PLUGINS_DIR="$HOME/.zsh/plugins"
mkdir -p "$ZSH_PLUGINS_DIR"

# Clone zsh plugins
declare -A ZSH_PLUGINS
ZSH_PLUGINS["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions.git"
ZSH_PLUGINS["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting.git"
ZSH_PLUGINS["zsh-fzf-tab"]="https://github.com/Aloxaf/fzf-tab.git"
ZSH_PLUGINS["fzf-tab-completion"]="https://github.com/lincheney/fzf-tab-completion.git"

for plugin in "${!ZSH_PLUGINS[@]}"; do
    if [ ! -d "$ZSH_PLUGINS_DIR/$plugin" ]; then
        echo "Installing $plugin..."
        git clone "${ZSH_PLUGINS[$plugin]}" "$ZSH_PLUGINS_DIR/$plugin"
    else
        echo "$plugin already installed"
    fi
done

# Set up yazi plugins
echo "Setting up yazi plugins..."
YAZI_PLUGINS_DIR="$HOME/.config/yazi/plugins"
mkdir -p "$YAZI_PLUGINS_DIR"

declare -A YAZI_PLUGINS
YAZI_PLUGINS["zoxide"]="https://github.com/yazi-rs/plugins/tree/main/zoxide.yazi"
YAZI_PLUGINS["session"]="https://github.com/yazi-rs/plugins/tree/main/session.yazi"
YAZI_PLUGINS["fr"]="https://github.com/yazi-rs/plugins/tree/main/fr.yazi"
YAZI_PLUGINS["smart-enter"]="https://github.com/ourongxing/smart-enter.yazi.git"
YAZI_PLUGINS["compress"]="https://github.com/yazi-rs/plugins/tree/main/compress.yazi"

# Note: Most yazi plugins are in the yazi-rs/plugins repo
# We'll install them using ya pack
if command -v ya &> /dev/null; then
    echo "Installing yazi plugins using ya pack..."
    ya pack -a yazi-rs/plugins:zoxide
    ya pack -a yazi-rs/plugins:session
    ya pack -a yazi-rs/plugins:fr
    ya pack -a yazi-rs/plugins:compress
    ya pack -a ourongxing/smart-enter
else
    echo "Warning: 'ya' command not found. Install yazi plugins manually."
fi

# Copy configs
echo "Copying config files..."

# Backup existing configs
if [ -f "$HOME/.zshrc" ]; then
    echo "Backing up existing .zshrc to .zshrc.backup"
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup"
fi

# Copy zshrc
echo "Installing .zshrc..."
cp "$SCRIPT_DIR/linux.zshrc" "$HOME/.zshrc"

# Copy yazi configs
echo "Installing yazi configs..."
mkdir -p "$HOME/.config/yazi"
cp -r "$SCRIPT_DIR/.config/yazi/"* "$HOME/.config/yazi/"

# Copy zellij configs
echo "Installing zellij configs..."
mkdir -p "$HOME/.config/zellij/layouts"
cp -r "$SCRIPT_DIR/.config/zellij/"* "$HOME/.config/zellij/"

# Set zsh as default shell
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
    echo "Note: You need to log out and back in for the shell change to take effect"
fi

# Create secrets file template
if [ ! -f "$HOME/.secrets" ]; then
    echo "Creating ~/.secrets template..."
    cat > "$HOME/.secrets" << 'EOF'
# ~/.secrets
# Add your API keys and secrets here
# This file is sourced by .zshrc

# Example:
# export OPENAI_API_KEY="your-key-here"
# export ANTHROPIC_API_KEY="your-key-here"
EOF
    chmod 600 "$HOME/.secrets"
    echo "Created ~/.secrets - add your API keys there"
fi

echo ""
echo "======================================"
echo "Setup complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Log out and log back in (or run 'exec zsh') to start using zsh"
echo "2. Add your API keys to ~/.secrets"
echo "3. Install any additional tools you need"
echo ""
echo "Installed configs:"
echo "  - ~/.zshrc"
echo "  - ~/.config/yazi/"
echo "  - ~/.config/zellij/"
echo ""
