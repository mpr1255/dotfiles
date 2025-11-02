
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

# Check if we need to install anything
NEEDS_INSTALL=false
for tool in zsh git curl wget ripgrep bat eza zoxide fzf nvim sqlite3 mpv w3m; do
    if ! command -v $tool &> /dev/null; then
        NEEDS_INSTALL=true
        break
    fi
done

# Only update package lists if we need to install something
if [ "$NEEDS_INSTALL" = true ]; then
    echo "Updating package lists..."
    if [ "$PKG_MANAGER" = "apt" ]; then
        sudo apt-get update
    elif [ "$PKG_MANAGER" = "dnf" ]; then
        sudo dnf check-update || true
    fi
else
    echo "All system packages already installed, skipping apt update"
fi

# Install basic tools only if needed
for tool in zsh git curl wget unzip; do
    if ! command -v $tool &> /dev/null; then
        echo "Installing $tool..."
        $INSTALL_CMD $tool
    fi
done

# Install build tools only if gcc not present
if ! command -v gcc &> /dev/null; then
    echo "Installing build tools..."
    if [ "$PKG_MANAGER" = "apt" ]; then
        $INSTALL_CMD build-essential
    elif [ "$PKG_MANAGER" = "dnf" ]; then
        $INSTALL_CMD gcc gcc-c++ make
    elif [ "$PKG_MANAGER" = "pacman" ]; then
        $INSTALL_CMD base-devel
    fi
fi

# Install modern CLI tools only if needed
for tool in ripgrep eza zoxide neovim sqlite3 mpv w3m; do
    if ! command -v $tool &> /dev/null && ! command -v nvim &> /dev/null; then
        echo "Installing $tool..."
        $INSTALL_CMD $tool 2>/dev/null || echo "Warning: Could not install $tool"
    fi
done

# Install Node.js and npm
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
    echo "Installing Node.js and npm..."
    if [ "$PKG_MANAGER" = "apt" ]; then
        # Install Node.js LTS via NodeSource
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        $INSTALL_CMD nodejs
    else
        $INSTALL_CMD nodejs npm
    fi
else
    echo "Node.js and npm already installed"
fi

# Install bun (modern JavaScript runtime and package manager)
if ! command -v bun &> /dev/null; then
    echo "Installing bun..."
    curl -fsSL https://bun.sh/install | bash
    # Add bun to PATH for current session
    export PATH="$HOME/.bun/bin:$PATH"
else
    echo "bun already installed"
fi

# Install document processing tools for yazi
echo "Installing document processing tools..."
for tool in antiword pandoc poppler-utils; do
    if ! dpkg -l | grep -q "^ii  $tool"; then
        echo "Installing $tool..."
        $INSTALL_CMD $tool 2>/dev/null || echo "Warning: Could not install $tool"
    fi
done

# Install Python-based tools via uv
echo "Installing Python-based CLI tools..."
if command -v uv &> /dev/null; then
    # Install csvkit and visidata for data processing
    uv tool install csvkit 2>/dev/null || echo "Warning: Could not install csvkit"
    uv tool install visidata 2>/dev/null || echo "Warning: Could not install visidata"
fi

# Install fzf properly with setup
if ! command -v fzf &> /dev/null; then
    echo "Installing fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish
else
    # If fzf exists but not properly set up, run install
    if [ ! -f ~/.fzf.zsh ]; then
        echo "Setting up fzf keybindings..."
        if [ -d ~/.fzf ]; then
            ~/.fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish
        fi
    fi
fi

# Install bat (Ubuntu installs as 'batcat')
if ! command -v bat &> /dev/null; then
    echo "Installing bat..."
    if [ "$PKG_MANAGER" = "apt" ]; then
        $INSTALL_CMD bat
        # Ubuntu installs bat as batcat - create symlink
        mkdir -p "$HOME/.local/bin"
        if [ -f /usr/bin/batcat ]; then
            ln -sf /usr/bin/batcat "$HOME/.local/bin/bat"
        fi
    else
        $INSTALL_CMD bat
    fi
fi

# Install fd-find (special case - Ubuntu uses fdfind)
if ! command -v fd &> /dev/null && ! command -v fdfind &> /dev/null; then
    echo "Installing fd..."
    if [ "$PKG_MANAGER" = "apt" ]; then
        $INSTALL_CMD fd-find
        mkdir -p "$HOME/.local/bin"
        if [ -f /usr/bin/fdfind ]; then
            ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd"
        fi
    else
        $INSTALL_CMD fd
    fi
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

# Install yazi from official releases (not cargo - cargo builds have issues)
if ! command -v yazi &> /dev/null; then
    echo "Installing yazi from GitHub releases..."
    YAZI_TEMP="/tmp/yazi-install"
    mkdir -p "$YAZI_TEMP"
    cd "$YAZI_TEMP"
    curl -fsSL https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip -o yazi.zip
    unzip -o yazi.zip
    sudo cp yazi-x86_64-unknown-linux-gnu/yazi yazi-x86_64-unknown-linux-gnu/ya /usr/local/bin/
    cd -
    rm -rf "$YAZI_TEMP"
    echo "yazi installed from official releases"
else
    echo "yazi already installed"
fi

# Install file command (required by yazi for mime detection)
if ! command -v file &> /dev/null; then
    echo "Installing file command..."
    $INSTALL_CMD file 2>/dev/null || echo "Warning: Could not install file"
else
    echo "file command already installed"
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
    "ouch"  # archive previews for yazi
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

# Note: We use uv for all Python package management
# sqlite-utils and other Python tools can be installed with:
#   uvx sqlite-utils [args]
# or:
#   uv tool install sqlite-utils

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

# Copy configs FIRST (before installing plugins)
echo "Copying config files..."

# Backup existing configs
if [ -f "$HOME/.zshrc" ]; then
    echo "Backing up existing .zshrc to .zshrc.backup"
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup"
fi

# Copy zshrc
echo "Installing .zshrc..."
cp "$SCRIPT_DIR/linux.zshrc" "$HOME/.zshrc"

# Copy yazi configs including plugins directory
echo "Installing yazi configs and plugins..."
mkdir -p "$HOME/.config/yazi"
cp -r "$SCRIPT_DIR/.config/yazi/"* "$HOME/.config/yazi/"

# Note: yazi plugins are ready to use
# - zoxide and session are built-in preset plugins
# - fr, compress, and smart-enter are included in .config/yazi/plugins/

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

# Add exec zsh to bashrc for immediate zsh startup (until logout/login)
if [ -f "$HOME/.bashrc" ]; then
    if ! grep -q "exec zsh" "$HOME/.bashrc"; then
        echo "Adding 'exec zsh' to ~/.bashrc for immediate zsh startup..."
        echo "" >> "$HOME/.bashrc"
        echo "# Auto-start zsh (added by dotfiles setup.sh)" >> "$HOME/.bashrc"
        echo "if [ -x /usr/bin/zsh ]; then" >> "$HOME/.bashrc"
        echo "    exec zsh" >> "$HOME/.bashrc"
        echo "fi" >> "$HOME/.bashrc"
    fi
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
echo "Installed configs:"
echo "  - ~/.zshrc (shell configuration)"
echo "  - ~/.config/yazi/ (file manager)"
echo "  - ~/.config/zellij/ (terminal multiplexer)"
echo "  - ~/.fzf.zsh (fuzzy finder keybindings)"
echo "  - ~/.secrets (API keys template)"
echo ""
echo "Keybindings:"
echo "  - Ctrl+T: fzf file search"
echo "  - Ctrl+R: mcfly history search"
echo "  - n: yazi file manager (with zoxide, session, fr, compress plugins)"
echo "  - zl: zellij terminal multiplexer"
echo ""
echo "======================================"
echo "Starting zsh now..."
echo "======================================"
echo ""

# Switch to zsh automatically
exec zsh
