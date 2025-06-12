# Preferred shell settings
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git z npm colorize)

source $ZSH/oh-my-zsh.sh

# --- colourised LS via colorls ---------------------------------------------
if command -v colorls &>/dev/null; then
  alias ls='colorls --dark --group-directories-first --git-status'
fi

# --- misc -------------------------------------------------------------------
export EDITOR="nvim"
export HOMEBREW_NO_ANALYTICS=1
