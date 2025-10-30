# ~/.zshrc for Linux systems
# Sanitized version without API keys or Mac-specific paths

# --- Basic Zsh Setup ---
typeset -U path cdpath fpath manpath

# --- Zsh Plugin Management ---
ZSH_PLUGINS_DIR="$HOME/.zsh/plugins"
fpath+=($ZSH_PLUGINS_DIR/zsh-fzf-tab)

# --- Zsh Completion System ---
autoload -U compinit
compinit
autoload -U edit-command-line
zle -N edit-command-line

# Load zsh plugins if they exist
if [[ -f "$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh" ]]; then
  source "$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh"
fi

if [[ -f "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh" ]]; then
  source "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh"
fi

if [[ -f "$ZSH_PLUGINS_DIR/fzf-tab-completion/zsh/fzf-tab-completion.zsh" ]]; then
  source "$ZSH_PLUGINS_DIR/fzf-tab-completion/zsh/fzf-tab-completion.zsh"
fi

FZF_TAB_PLUGIN_PATH="$HOME/.zsh/plugins/zsh-fzf-tab/fzf-tab.plugin.zsh"
if [[ -f "$FZF_TAB_PLUGIN_PATH" ]]; then
  source "$FZF_TAB_PLUGIN_PATH"
fi

# --- History ---
HISTSIZE="10000"
SAVEHIST="10000"
HISTFILE="$HOME/.zsh_history"
mkdir -p "$(dirname "$HISTFILE")"
# Create history file if it doesn't exist
touch "$HISTFILE"
setopt HIST_FCNTL_LOCK
setopt HIST_IGNORE_DUPS
unsetopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
unsetopt HIST_EXPIRE_DUPS_FIRST
setopt SHARE_HISTORY
unsetopt EXTENDED_HISTORY

# --- Keybindings ---
bindkey -e # Use emacs keybindings
bindkey '^ ' autosuggest-execute
bindkey '^[^[[B' autosuggest-fetch
bindkey '^X^E' edit-command-line

# --- Environment Variables ---
export PATH="$HOME/bin:$HOME/go/bin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# Editors & Pagers
export VISUAL='nvim'
export EDITOR="nvim"
export PAGER="less -R"
export MANPAGER="sh -c 'col -bx | bat -l man -p'" # Requires bat

# Tools & Config
export GPG_TTY=$(tty)
export CLICOLOR=2
export TERM=xterm-256color
export MCFLY_RESULTS=1000
export FZF_DEFAULT_COMMAND="fd --no-ignore --exclude venv -L ."
export FZF_DEFAULT_OPTS='--height 40% --layout reverse --border top'
export FZF_CTRL_T_OPTS="--preview '(highlight -O ansi -l {} 2> /dev/null || cat {} || tree -C {}) 2> /dev/null | head -200'"
export FZF_CTRL_T_OPTS="--select-1 --exit-0"
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"


# Textra (if installed manually)
export TEXTRA_INSTALL="$HOME/.textra"
export PATH="$TEXTRA_INSTALL/bin:$PATH"

# API Keys - Load from ~/.secrets if it exists
if [[ -f "$HOME/.secrets" ]]; then
  source "$HOME/.secrets"
fi

# Rust/Cargo environment
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Zsh Autosuggestions strategy
ZSH_AUTOSUGGEST_STRATEGY=(history match_prev_cmd)

# --- Tool Initializations ---

# fzf (Keybindings and fuzzy completion)
if command -v fzf &> /dev/null; then
  source <(fzf --zsh)
fi

# zoxide (Smarter cd)
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

# mcfly
if command -v mcfly &> /dev/null; then
  eval "$(mcfly init zsh)"
fi

# uv
if command -v uvx &> /dev/null; then
  eval "$(uvx --generate-shell-completion zsh)"
fi

# starship prompt
if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi

# fzf completion bindings
bindkey '^I' fzf-completion

# --- FZF / Completion Styling (zstyle) ---
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' fzf-flags --color=fg:3,fg+:2 --bind=tab:accept
zstyle ':fzf-tab:*' use-fzf-default-opts no
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':completion:*' menu select

# --- Custom Functions ---
function take() {
  mkdir -p "$1" && cd "$1"
}

function yazi-launcher() {
  if [ "${YAZILVL:-0}" -ne 0 ]; then echo "yazi is already running"; return; fi
  export YAZILVL=$((YAZILVL+1))
  local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
      cd -- "$cwd"
  fi
  rm -f -- "$tmp"
  export YAZILVL=0
}

function rga-fzf() {
    local query="$1"
    local extension="$2"
    local RG_PREFIX="rga --files-with-matches --no-ignore --smart-case"
    [[ ! -z "$extension" ]] && RG_PREFIX="$RG_PREFIX -g '*.$extension'"
    local rg_pattern=$(echo "$query" | sed 's/[[:space:]]\+/.*\\&/g')

    FZF_DEFAULT_COMMAND="$RG_PREFIX '$rg_pattern'" \
        fzf --sort \
            --preview="[[ ! -z {} ]] && rga --colors 'match:bg:yellow' --pretty --context 10 '$rg_pattern' {} | less -R" \
            --multi \
            --phony -q "$query" \
            --color "hl:-1:underline,hl+:-1:underline:reverse" \
            --bind "change:reload:$RG_PREFIX {q}" \
            --preview-window="50%:wrap" \
            --bind "enter:execute-silent(echo {} | xargs -n 1 xdg-open)"
}

# Tailscale exit node switcher (customize with your own exit nodes)
# Example usage after customization: ts frankfurt, ts none
# function ts() {
#   case "$1" in
#     frankfurt) tailscale set --exit-node=your-exit-node-here ;;
#     none) tailscale set --exit-node= ;;
#     *) echo "Usage: ts {frankfurt|none}" ;;
#   esac
# }

# --- Aliases ---
alias prettyhtml='tidy -iq | bat -l html'
alias ls='eza'
alias ftp='files-to-prompt'
alias ll='eza -alh'
alias tree='eza --tree'
alias cat='bat --plain'
alias rg='rg -i'
alias fd='fd --hidden --follow --exclude .git'
alias s='source ./.venv/bin/activate'
alias n='yazi-launcher'
alias zup='zoxide add .'
alias zi='zoxide query -i'

# Tool aliases
alias sqlite='sqlite3'
alias squ='uvx sqlite-utils'
alias r='radian'
alias zl='zellij'
alias fabric='fabric-ai'

# Local bin path
export PATH="$PATH:$HOME/.local/bin"

# Source fzf-tab if it exists
if [[ -f "$ZSH_PLUGINS_DIR/zsh-fzf-tab/zsh-fzf-tab.plugin.zsh" ]]; then
  source "$ZSH_PLUGINS_DIR/zsh-fzf-tab/zsh-fzf-tab.plugin.zsh"
fi

function ssh() {
  local host
  for arg in "$@"; do
    [[ "$arg" != -* ]] && { host="$arg"; break; }
  done

  # Terminal color customization based on SSH host
  if [[ "$host" == *devbox* ]]; then
    printf '\e]11;#004D40\e\\'; printf '\e]10;#E0F2F1\e\\' # Dark Teal
  elif [[ "$host" == *workbench* ]]; then
    printf '\e]11;#1C1C1C\e\\'; printf '\e]10;#E0E0E0\e\\' # Dark Gray
  fi

  command ssh "$@"

  # Reset colors after ssh
  printf '\e]11;\e\\'; printf '\e]10;\e\\'
}

export PATH="$HOME/bin:$PATH"

run_at_time() {
    local target_time=$1
    shift

    local target_epoch=$(date -d "$target_time" "+%s" 2>/dev/null)
    local current_epoch=$(date "+%s")
    local sleep_seconds=$((target_epoch - current_epoch))

    if [ $sleep_seconds -lt 0 ]; then
        sleep_seconds=$((sleep_seconds + 86400))
    fi

    echo "Scheduling command to run at $target_time (in $sleep_seconds seconds)"
    (sleep $sleep_seconds && echo -e "\n\033[1;32m[$(date)] Running scheduled command:\033[0m" && "$@") &
}

ulimit -n 4096
