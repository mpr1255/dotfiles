# Manual Zsh Environment Setup for macOS

This guide explains how to set up your Zsh environment using Homebrew, manual plugin management via Git, and the provided configuration files. This aims to replicate a setup previously managed by Nix/Home Manager, using standard macOS tools.

## Components

1.  **`Brewfile`**: Lists Homebrew packages (formulae and casks) to install using `brew bundle`.
2.  **`install_plugins.sh`**: Script to download required Zsh plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-fzf-tab`, `spaceship-prompt`, `zsh-autocomplete`) into `~/.zsh/plugins/` using Git.
3.  **`.zshrc`**: The main Zsh configuration file. **Crucially, use the provided `.zshrc` file which has been specifically updated** to work correctly with `zsh-autocomplete` (it sources it first and disables `compinit`).

## Setup Steps (Perform in Order)

1.  **Install Homebrew**:
    *   If you don't have Homebrew, install it from [brew.sh](https://brew.sh/).

2.  **Place Configuration Files**:
    *   Copy the `Brewfile` to your home directory (`~`).
    *   Copy the `install_plugins.sh` script to your home directory (`~`).
    *   Copy the **updated `.zshrc` file** (the one from step 1 above) to a temporary location or note where you saved it. You will place it at `~/.zshrc` later.

3.  **Install Brew Packages**:
    *   Open your Terminal.
    *   Navigate to your home directory: `cd ~`
    *   Run the Brew Bundle command: `brew bundle install`
    *   This installs all CLI tools and GUI apps listed in the `Brewfile`.
    *   **Critical Post-Install Step:** Run the `fzf` setup script:
        ```bash
        $(brew --prefix)/opt/fzf/install
        ```
        Follow its prompts (usually say 'yes' to enable keybindings and completion; it might offer to modify `.zshrc` - this is generally safe, but review if concerned).

4.  **Install Zsh Plugins**:
    *   Make the script executable: `chmod +x ~/install_plugins.sh`
    *   Run the script: `~/install_plugins.sh`
    *   This downloads the plugins into `~/.zsh/plugins/`. Check the output for any errors.

5.  **Apply Zsh Configuration**:
    *   **Backup your existing `~/.zshrc` if you have one:**
        ```bash
        mv ~/.zshrc ~/.zshrc.backup_$(date +%Y%m%d_%H%M%S)
        ```
    *   Copy the **updated `.zshrc` file** (from Step 1 of this guide) to `~/.zshrc`:
        ```bash
        cp /path/to/where/you/saved/updated.zshrc ~/.zshrc
        ```
        (Replace `/path/to/where/you/saved/updated.zshrc` with the actual path).

6.  **Restart Your Shell**: For all changes (Homebrew paths, plugins, `.zshrc`) to take effect, either:
    *   Close **all** open terminal windows/tabs and open a new one.
    *   Or, run: `exec zsh`

7.  **Configure Terminal Font**:
    *   For icons (`eza`, prompts, LazyVim) to display correctly, configure your terminal emulator (iTerm2, macOS Terminal, etc.) to use a **Nerd Font** (e.g., "Hack Nerd Font", installed by the `Brewfile`). Find this in your terminal's Profile/Text/Font settings.

## zprofile

The only thing that's in there is 


eval "$(/opt/homebrew/bin/brew shellenv)"



## Post-Setup Checks & Manual Steps

*   **Test Completions**: Type commands and press `Tab`. You should see completions managed by `zsh-autocomplete`. Check if suggestions from `zsh-autosuggestions` appear as you type.
*   **Test Keybindings**: Verify `Ctrl+T` (fzf file finder), `Ctrl+R` (mcfly history).
*   **Custom Scripts**: Ensure personal scripts (e.g., `~/bin/knit_invoice.sh`) are in a `$PATH` directory and executable (`chmod +x`).
*   **API Keys/Credentials**: Double-check paths and consider secure management options if needed.
*   **LazyVim**: If you installed LazyVim, launch `nvim` and ensure it loads correctly and icons render properly (requires Nerd Font).

You should now have a working Zsh environment based on these manual steps! Remember to update plugins occasionally by running `git -C ~/.zsh/plugins/<plugin_name> pull` or re-running the `install_plugins.sh` script (though the latter might fail if directories already exist - manual pulls are safer for updates).
