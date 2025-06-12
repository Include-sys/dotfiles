# Preferred shell settings
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=( git zsh-syntax-highlighting zsh-autosuggestions encode64 tmux urltools fzf)

source $ZSH/oh-my-zsh.sh

# --- colourised LS via colorls ---------------------------------------------
if command -v colorls &>/dev/null; then
    alias ld='colorls -d'
    alias lf='colorls -f'
    alias lh='colorls -S'
    alias ll='colorls -al --sd'
    alias ls='colorls -al -a'
    alias lt='colorls -al -t'
fi

# --- misc -------------------------------------------------------------------
export EDITOR="nvim"
export HOMEBREW_NO_ANALYTICS=1
