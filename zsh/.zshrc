#!/usr/bin/env zsh
# Enhanced .zshrc - Stow-managed dotfiles
# Created: $(date +%Y-%m-%d)
# Author: jk1rby

# ============================================================================
# EARLY INITIALIZATION
# ============================================================================

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ============================================================================
# ZSH CONFIGURATION
# ============================================================================

# Oh-My-Zsh Installation Path
export ZSH="$HOME/.oh-my-zsh"

# Theme Configuration
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    docker
    docker-compose
    python
    pip
    conda-env
    command-not-found
    colored-man-pages
    extract
    web-search
    history
    you-should-use
)

# Load Oh-My-Zsh (install if not present)
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh"
else
    echo "Oh-My-Zsh not found. Install with:"
    echo "sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
fi

# ============================================================================
# HISTORY CONFIGURATION
# ============================================================================

HISTSIZE=10000
HISTFILESIZE=20000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# History options
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE
setopt HIST_NO_STORE
setopt HIST_EXPIRE_DUPS_FIRST
setopt EXTENDED_HISTORY

# ============================================================================
# SHELL OPTIONS
# ============================================================================

autoload -U colors && colors

setopt AUTO_CD
setopt CORRECT
setopt CORRECT_ALL
setopt GLOB_COMPLETE
setopt EXTENDED_GLOB
setopt NO_CASE_GLOB
setopt NUMERIC_GLOB_SORT
setopt AUTO_LIST
setopt AUTO_MENU
setopt ALWAYS_TO_END
setopt COMPLETE_IN_WORD
setopt MENU_COMPLETE

# ============================================================================
# COMPLETION SYSTEM
# ============================================================================

autoload -U compinit && compinit

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(@s.:.)LS_COLORS}"
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# ============================================================================
# ENVIRONMENT VARIABLES
# ============================================================================

export TERM="xterm-256color"
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export LESS='-R -M -I -S -x4'
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# ============================================================================
# PATH CONFIGURATION
# ============================================================================

add_to_path() {
    if [[ -d "$1" && ":$PATH:" != *":$1:"* ]]; then
        export PATH="$1:$PATH"
    fi
}

add_to_path "/usr/local/bin"
add_to_path "/usr/local/sbin"
add_to_path "$HOME/.local/bin"
add_to_path "/usr/bin"
add_to_path "/usr/local/bin/ignition"
add_to_path "$HOME/snap/code/196/.local/share/reflex/bun/bin"

# ============================================================================
# MODERN COMMAND REPLACEMENTS
# ============================================================================

if command -v exa >/dev/null 2>&1; then
    alias ls='exa --icons --group-directories-first'
    alias la='exa -la --icons --group-directories-first'
    alias ll='exa -lg --icons --group-directories-first'
    alias lt='exa --tree --level=2 --icons'
else
    alias ls='ls --color=auto --group-directories-first'
    alias la='ls -lahF'
    alias ll='ls -alF'
fi

if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
    alias ccat='bat --paging=never --plain'
fi

if command -v fd >/dev/null 2>&1; then
    alias find='fd'
fi

if command -v rg >/dev/null 2>&1; then
    alias grep='rg'
else
    alias grep='grep --color=auto'
fi

if command -v htop >/dev/null 2>&1; then
    alias top='htop'
fi

# ============================================================================
# ALIASES
# ============================================================================

# Basic aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# Editor aliases
alias v='nvim'
alias vim='nvim'
alias e='$EDITOR'
alias zshrc='$EDITOR ~/.zshrc'

# Git aliases
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gca='git commit -a'
alias gcam='git commit -a -m'
alias gcm='git commit -m'
alias gco='git checkout'
alias gd='git diff'
alias gf='git fetch'
alias gl='git log --oneline --graph --decorate --all'
alias gp='git push'
alias gpl='git pull'
alias gs='git status'
alias gst='git stash'

# System aliases
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ps='ps aux'
alias mkdir='mkdir -pv'
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# Development aliases
alias py='python3'
alias pip='pip3'
alias serve='python3 -m http.server'

# Docker aliases
alias dk='docker'
alias dkc='docker-compose'
alias dkps='docker ps'
alias dki='docker images'

# ============================================================================
# FUNCTIONS
# ============================================================================

extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

mkcd() {
    mkdir -p "$1" && cd "$1"
}

# ============================================================================
# TOOL INTEGRATIONS
# ============================================================================

# ROS2 Integration
if [[ -f "/opt/ros/humble/setup.zsh" ]]; then
    source "/opt/ros/humble/setup.zsh"
elif [[ -f "/opt/ros/humble/setup.sh" ]]; then
    source "/opt/ros/humble/setup.sh"
fi

# NVM Integration
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    source "$NVM_DIR/nvm.sh"
fi
if [[ -s "$NVM_DIR/bash_completion" ]]; then
    source "$NVM_DIR/bash_completion"
fi

# Conda Integration
if [[ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]]; then
    source "$HOME/miniconda3/etc/profile.d/conda.sh"
elif [[ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]]; then
    source "$HOME/anaconda3/etc/profile.d/conda.sh"
fi

# Environment variables from original config
export LD_LIBRARY_PATH="$HOME/.local/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"
export GI_TYPELIB_PATH="$HOME/.local/lib/x86_64-linux-gnu/girepository-1.0:$GI_TYPELIB_PATH"
export XDG_DATA_DIRS="$HOME/.local/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
export BUN_INSTALL="$HOME/snap/code/196/.local/share/reflex/bun"

# Custom aliases from original config
alias ignition="/usr/local/bin/ignition/ignition.sh"
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# ============================================================================
# LOAD ADDITIONAL CONFIGURATIONS
# ============================================================================

# Load local configurations
if [[ -f ~/.zshrc.local ]]; then
    source ~/.zshrc.local
fi

# Load private configurations
if [[ -f ~/.zshrc.private ]]; then
    source ~/.zshrc.private
fi

# Load Powerlevel10k configuration
if [[ -f ~/.p10k.zsh ]]; then
    source ~/.p10k.zsh
fi

# ============================================================================
# WELCOME MESSAGE (after P10k initialization)
# ============================================================================

# Function to show welcome message after P10k loads
show_welcome() {
    if [[ -o interactive ]]; then
        echo -e "\n\033[1;32mWelcome to your enhanced Zsh environment!\033[0m"
        echo -e "Editor: $EDITOR"
        if command -v git >/dev/null; then
            echo -e "Git: $(git --version)"
        fi
        if command -v nvim >/dev/null; then
            echo -e "Neovim: $(nvim --version | head -1)"
        fi
        echo
    fi
}

# Only show welcome on login shells, not for each new terminal
if [[ -o login ]]; then
    # Delay welcome message to avoid P10k instant prompt conflicts
    zmodload zsh/datetime
    if (( EPOCHSECONDS - ${ZDOTDIR:-$HOME}/.zsh_last_welcome > 300 )); then
        show_welcome
        echo $EPOCHSECONDS > ${ZDOTDIR:-$HOME}/.zsh_last_welcome
    fi
fi
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
