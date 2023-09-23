# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="agnoster"
# Plugins for Oh My Zsh
plugins=(git zsh-autosuggestions autojump history pip python)
# aliases
alias ls="exa"
alias ll="exa -alh"
alias tree="exa --tree"
alias cat="bat -p"
alias catdoc="soffice --headless --cat"
alias n="nnn -d -e -Tt -x -A -u" #https://github.com/jarun/nnn/wiki/Usage#program-options 
alias s="source ./venv/bin/activate"


# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh
# Additional settings
export EDITOR="nvim"
export NNN_PLUG='f:finder;o:fzopen;p:mocq;d:diffs;t:nmount;v:preview-tui;z:autojump'
export PATH="$HOME/bin:$PATH"
export NNN_TRASH=1
export NNN_FIFO=/tmp/nnn.fifo
export CLICOLOR=2
export MCFLY_RESULTS=500
export CLICOLOR=1
export TERM=xterm-256color
# Initialize fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# Initialize autojump
[ -f /usr/share/autojump/autojump.sh ] && source /usr/share/autojump/autojump.sh
# Add your custom functions and exports after this line
eval "$(zoxide init zsh)"
autoload -U bashcompinit
bashcompinit

rga-fzf() {
    RG_PREFIX="rga --files-with-matches"
    local file
    file="$(
        FZF_DEFAULT_COMMAND="$RG_PREFIX '$1'" \
            fzf --sort --preview="[[ ! -z {} ]] && rga --pretty --context 5 {q} {}" \
                --phony -q "$1" \
                --bind "change:reload:$RG_PREFIX {q}" \
                --preview-window="70%:wrap"
    )" &&
    echo "opening $file" &&
    xdg-open "$file"
}
eval "$(mcfly init zsh)"

export PATH=$PATH:/usr/bin/batcat
export ZELLIJ_CONFIG_FILE_PATH=~/dotfiles/zellij-config.yml


# Launch Zellij
if [ -z "$ZELLIJ_SESSION" ]; then
  export ZELLIJ_SESSION=1
  zellij
fi