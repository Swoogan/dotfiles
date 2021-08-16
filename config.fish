#if test -z (pgrep ssh-agent)
#  eval (ssh-agent -c)
#  set -gx SSH_AUTH_SOCK $SSH_AUTH_SOCK
#  set -gx SSH_AGENT_PID $SSH_AGENT_PID
#  set -gx SSH_AUTH_SOCK $SSH_AUTH_SOCK
#end

source ~/.local/config.fish

set -gx DEV_HOME "$HOME/dev"
set -gx EDITOR "/usr/bin/nvim"
set -gx SUDO_EDITOR (which nvim)

set -gx WASMTIME_HOME "$HOME/.wasmtime"

# Wasmer config
set -gx WASMER_DIR "$HOME/.wasmer"
set -gx WASMER_CACHE_DIR "$WASMER_DIR/cache"

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ls='exa'
alias ll='exa --long'
alias lg='exa --long --git'
alias ec='nvim ~/.config/fish/config.fish'
alias up='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'

# Wasmer
[ -s "$WASMER_DIR/wasmer.sh" ] && source "$WASMER_DIR/wasmer.sh"
