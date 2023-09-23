# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="agnoster"

# Plugins for Oh My Zsh
plugins=(git zsh-autosuggestions autojump history pip python)

# Load Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Additional settings
export EDITOR="nvim"
export PATH="$HOME/bin:$PATH"
export ZSH="$HOME/.oh-my-zsh"
export NNN_TRASH=1
export NNN_FIFO=/tmp/nnn.fifo
export CLICOLOR=2
export MCFLY_RESULTS=500

# Initialize fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Initialize autojump
[ -f /usr/share/autojump/autojump.sh ] && source /usr/share/autojump/autojump.sh

# Add your custom functions and exports after this line
source $ZSH/oh-my-zsh.sh
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(zoxide init zsh)"
autoload -U bashcompinit
bashcompinit