function source_local
    if test -e $argv[1]
        source $argv[1]
    end
end

### PRE ###
source_local ~/.local/pre.fish

### BODY ###

set NVIM (which nvim)

set -gx DEV_HOME "$HOME/dev"
set -gx EDITOR $NVIM
set -gx SUDO_EDITOR $NVIM

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

# Keychain
/usr/bin/keychain -q --nogui $HOME/.ssh/id_rsa

if test -f ~/.keychain/(hostname)-fish
    source ~/.keychain/(hostname)-fish
end

# Wasmer
[ -s "$WASMER_DIR/wasmer.sh" ] && source "$WASMER_DIR/wasmer.sh"

### POST ###
source_local ~/.local/post.fish
