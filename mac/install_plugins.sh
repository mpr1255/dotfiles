#!/usr/bin/env bash

# Script to download Zsh plugins via Git and set up LazyVim

# Define the directory where plugins will be installed
PLUGINS_DIR="${HOME}/.zsh/plugins"

# Create the plugins directory if it doesn't exist (idempotent)
echo "Ensuring plugin directory exists: ${PLUGINS_DIR}"
mkdir -p "${PLUGINS_DIR}"

echo "-------------------------------------"
echo "Checking/Cloning Zsh plugins..."
echo "Target directory: ${PLUGINS_DIR}"
echo "-------------------------------------"

# Function to clone a repo if the target directory doesn't exist
clone_if_missing() {
  local repo_url=$1
  local target_dir=$2
  local plugin_name=$3
  if [ -d "${target_dir}" ]; then
    echo "${plugin_name} already exists at ${target_dir}. Skipping clone."
  else
    echo "Cloning ${plugin_name}..."
    git clone --depth 1 -- "${repo_url}" "${target_dir}" || echo "Failed to clone ${plugin_name}"
  fi
}

# Clone Zsh plugins using the function
clone_if_missing "https://github.com/zsh-users/zsh-autosuggestions.git" "${PLUGINS_DIR}/zsh-autosuggestions" "zsh-autosuggestions"
clone_if_missing "https://github.com/zsh-users/zsh-syntax-highlighting.git" "${PLUGINS_DIR}/zsh-syntax-highlighting" "zsh-syntax-highlighting"
clone_if_missing "https://github.com/Aloxaf/fzf-tab.git" "${PLUGINS_DIR}/zsh-fzf-tab" "zsh-fzf-tab"
clone_if_missing "https://github.com/lincheney/fzf-tab-completion.git" "${PLUGINS_DIR}/fzf-tab-completion" "fzf-tab-completion"
clone_if_missing "https://github.com/spaceship-prompt/spaceship-prompt.git" "${PLUGINS_DIR}/spaceship-prompt" "spaceship-prompt"
#clone_if_missing "https://github.com/marlonrichert/zsh-autocomplete.git" "${PLUGINS_DIR}/zsh-autocomplete" "zsh-autocomplete"

echo "-------------------------------------"
echo "Plugin checking/cloning process finished."
echo "Check for any 'Failed to clone' messages above."
echo "-------------------------------------"

# --- LazyVim Setup ---

echo # Add a blank line for separation
echo "-------------------------------------"
echo "Setting up LazyVim for Neovim..."
echo "Prerequisites: Neovim v0.8+ and Git must be installed."
echo "-------------------------------------"

# Define Neovim config and data directories
NVIM_CONFIG_DIR="${HOME}/.config/nvim"
NVIM_SHARE_DIR="${HOME}/.local/share/nvim"
NVIM_STATE_DIR="${HOME}/.local/state/nvim"
NVIM_CACHE_DIR="${HOME}/.cache/nvim"
BACKUP_SUFFIX=".bak" # Or use a timestamp: BACKUP_SUFFIX=".$(date +%Y%m%d_%H%M%S).bak"

# Function to backup a directory if it exists and backup doesn't already exist
backup_dir_if_needed() {
  local original_dir=$1
  local backup_dir="${original_dir}${BACKUP_SUFFIX}"
  if [ -d "${original_dir}" ] && [ ! -d "${backup_dir}" ] && [ ! -L "${backup_dir}" ]; then # Check if original exists and backup does NOT
    echo "Backing up ${original_dir} to ${backup_dir}"
    mv "${original_dir}" "${backup_dir}" || echo "Failed to backup ${original_dir}"
  elif [ -d "${backup_dir}" ]; then
    echo "Backup directory ${backup_dir} already exists. Skipping backup for ${original_dir}."
  elif [ ! -d "${original_dir}" ]; then
    echo "Original directory ${original_dir} not found. Skipping backup."
  fi
}

# Backup existing Neovim configuration and data (IMPORTANT!)
echo "Checking and backing up existing Neovim configuration and data (if found and not already backed up)..."
backup_dir_if_needed "${NVIM_CONFIG_DIR}"
backup_dir_if_needed "${NVIM_SHARE_DIR}"
backup_dir_if_needed "${NVIM_STATE_DIR}"
backup_dir_if_needed "${NVIM_CACHE_DIR}"

# Clone the LazyVim starter template if nvim config dir doesn't exist
if [ ! -d "${NVIM_CONFIG_DIR}" ]; then
  echo "Cloning LazyVim starter repository to ${NVIM_CONFIG_DIR}..."
  git clone https://github.com/LazyVim/starter "${NVIM_CONFIG_DIR}" || {
    echo "Failed to clone LazyVim starter repository. Aborting LazyVim setup."
    exit 1
  } # Exit if clone fails

  # Remove the .git folder from the cloned repo if it exists
  if [ -d "${NVIM_CONFIG_DIR}/.git" ]; then
    echo "Removing .git directory from ${NVIM_CONFIG_DIR}......"
    rm -rf "${NVIM_CONFIG_DIR}/.git" || echo "Failed to remove .git directory (might not be critical)"
  else
    echo ".git directory not found in ${NVIM_CONFIG_DIR}. Skipping removal."
  fi
else
  echo "Neovim config directory ${NVIM_CONFIG_DIR} already exists. Assuming LazyVim is set up or managed elsewhere. Skipping clone."
fi

# Ensure specific options are set in options.lua
OPTIONS_FILE="${NVIM_CONFIG_DIR}/lua/config/options.lua"
OPTION_LINE="vim.g.snacks_animate = false"
OPTION_COMMENT="-- Disable distracting animations (added by setup script)"

if [ -f "${OPTIONS_FILE}" ]; then
  echo "Checking Neovim options file: ${OPTIONS_FILE}"
  # Use grep -q to check if the line exists, suppressing output
  if grep -qF -- "${OPTION_LINE}" "${OPTIONS_FILE}"; then
    echo "Option '${OPTION_LINE}' already exists in ${OPTIONS_FILE}."
  else
    echo "Adding '${OPTION_LINE}' to ${OPTIONS_FILE}..."
    # Append the comment and the option line to the file
    echo "" >>"${OPTIONS_FILE}" # Add a newline for separation
    echo "${OPTION_COMMENT}" >>"${OPTIONS_FILE}"
    echo "${OPTION_LINE}" >>"${OPTIONS_FILE}"
    echo "Option added."
  fi
else
  echo "Warning: Neovim options file not found at ${OPTIONS_FILE}. Cannot ensure '${OPTION_LINE}' is set."
fi

echo "-------------------------------------"
echo "LazyVim setup steps completed."
echo "Check for any failure messages above."
echo "-------------------------------------"

# --- Git setup ----
echo
echo "-------------------------------------"
echo "Setting up global Git pre-commit hook to block files >99MB..."
mkdir -p ~/.git-templates/hooks
cat <<'EOF' >~/.git-templates/hooks/pre-commit
#!/bin/bash
maxsize=$((99*1024*1024))
large_files=$(git diff --cached --name-only | while read filename; do
  if [ -f "$filename" ]; then
    size=$(stat -f%z "$filename")
    if [ "$size" -gt "$maxsize" ]; then
      echo "$filename ($(($size/1024/1024))MB)"
    fi
  fi
done)
if [ -n "$large_files" ]; then
  echo "✋ Commit aborted! These files are larger than 99MB:"
  echo "$large_files"
  exit 1
fi
exit 0
EOF
chmod +x ~/.git-templates/hooks/pre-commit
git config --global init.templateDir '~/.git-templates'
echo "Global Git template for pre-commit hook installed."
echo "-------------------------------------"

# --- Final Instructions ---
echo # Add a blank line for separation
echo "====================================="
echo "Setup Complete!"
echo "====================================="
echo "1. Zsh Plugins:"
echo "   - Plugins are located in ${PLUGINS_DIR}."
echo "   - Ensure your ~/.zshrc file sources them correctly."
# echo "   - The provided .zshrc should be correctly set up for zsh-autocomplete." # Keep commented if plugin is commented out
echo
echo "2. LazyVim:"
echo "   - Configuration is in ${NVIM_CONFIG_DIR}."
echo "   - Make sure you have Neovim v0.8+ installed (\`nvim --version\`)."
echo "   - If this was the first time setting up LazyVim, run 'nvim'. It will automatically install necessary plugins."
echo "   - If you had previous Neovim config, it has been backed up with a '${BACKUP_SUFFIX}' suffix."
echo "====================================="
