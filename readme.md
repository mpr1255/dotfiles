# Linux dotfiles

Dotfiles for setting up a new Linux system (e.g., Hetzner bare metal server). Sanitized configs without API keys or personal information.

## Quick setup

### Option 1: Hetzner bootstrap (fresh server in rescue mode)

```bash
curl -fsSL https://raw.githubusercontent.com/mpr1255/dotfiles/master/hetzner-bootstrap.sh | bash
```

This sets up RAID-0, installs Ubuntu 24.04, creates `ubuntu` user with your SSH key, and installs all dotfiles. After reboot, SSH as `ubuntu@your-server-ip`.

### Option 2: Existing Linux system

**One-liner:**
```bash
curl -fsSL https://raw.githubusercontent.com/mpr1255/dotfiles/master/setup.sh | bash
```

**Or clone first (recommended):**
```bash
git clone https://github.com/mpr1255/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash setup.sh
exec zsh
```

## What gets installed

### System packages
- zsh, git, curl, wget, neovim, build-essential
- ripgrep, fd-find, bat, eza, fzf, zoxide
- sqlite3, jq, iperf3, 7zip, mpv, w3m, rclone
- Node.js, bun

### Rust/cargo tools
- yazi (file manager)
- zellij (terminal multiplexer)
- ripgrep-all (rga)
- files-to-prompt, ouch

### Other
- starship (prompt)
- mcfly (shell history)
- uv (Python package manager)
- devbox (portable dev environments)

### Zsh plugins
- zsh-autosuggestions
- zsh-syntax-highlighting
- fzf-tab, fzf-tab-completion

### Yazi plugins
- zoxide, session, fr, compress, smart-enter, projects, dragon

## Directory structure

```
.
├── hetzner-bootstrap.sh    # One-command Hetzner setup (RAID + OS + user + dotfiles)
├── setup.sh                # Main setup script (idempotent, safe to re-run)
├── setup-nosudocheck.sh    # Setup without sudo check (for special cases)
├── pre-setup.sh            # Creates user, sets up SSH (fresh servers only)
├── refresh_from_mac.sh     # Sync configs from Mac to repo
├── linux.zshrc             # Zsh configuration for Linux
├── .config/
│   ├── starship.toml       # Prompt configuration
│   ├── nvim/               # LazyVim configuration
│   │   ├── init.lua
│   │   └── lua/
│   │       ├── config/     # options, keymaps, autocmds
│   │       └── plugins/    # plugin configs
│   ├── yazi/               # File manager configuration
│   │   ├── yazi.toml       # Main config
│   │   ├── keymap.toml     # Keybindings
│   │   ├── init.lua
│   │   ├── plugins/        # Bundled plugins
│   │   └── flavors/        # Themes (catppuccin-mocha)
│   └── zellij/
│       ├── config.kdl      # Zellij configuration
│       └── layouts/
└── mac/                    # Mac-specific setup (Brewfile, etc.)
    ├── Brewfile            # Homebrew packages
    ├── install_plugins.sh  # Zsh/LazyVim plugin installer
    └── readme.md           # Mac setup instructions
```

## Keybindings

| Key | Action |
|-----|--------|
| `Ctrl+T` | fzf file search |
| `Ctrl+R` | mcfly history search |
| `n` | yazi file manager |
| `zl` | zellij multiplexer |

## API keys

The setup creates `~/.secrets` which is sourced by `.zshrc`. Add your keys there:

```bash
# ~/.secrets
export OPENAI_API_KEY="your-key-here"
export ANTHROPIC_API_KEY="your-key-here"
```

Set proper permissions: `chmod 600 ~/.secrets`

## Updating configs from Mac

```bash
cd ~/bin/dotfiles
./refresh_from_mac.sh
git add -A && git commit -m "Update configs from Mac"
git push
```

## Scripts

| Script | Purpose | Idempotent |
|--------|---------|------------|
| `setup.sh` | Main setup (as user with sudo) | Yes |
| `hetzner-bootstrap.sh` | Full Hetzner setup from rescue mode | Yes |
| `pre-setup.sh` | Create user + SSH (as root) | Yes |
| `refresh_from_mac.sh` | Sync Mac configs to repo | Yes |
