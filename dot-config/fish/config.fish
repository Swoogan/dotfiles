function source_exists
    if test -f $argv[1]
        source $argv[1]
    end
end

### PRE ###
source_exists ~/.local/pre.fish

### BODY ###

set NVIM (which nvim)

set -gx DEV_HOME "$HOME/dev"
set -gx STOW_DIR "$DEV_HOME/dotfiles"
set -gx EDITOR $NVIM
set -gx SUDO_EDITOR $NVIM

set -gx WASMTIME_HOME "$HOME/.wasmtime"

# Wasmer config
set -gx WASMER_DIR "$HOME/.wasmer"
set -gx WASMER_CACHE_DIR "$WASMER_DIR/cache"

# Wasmer
[ -s "$WASMER_DIR/wasmer.sh" ] && source "$WASMER_DIR/wasmer.sh"

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ls='exa'
alias ll='exa --long'
alias lg='exa --long --git'
alias ec='nvim ~/.config/fish/config.fish'
alias up='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'

# Keychain
if status --is-interactive
    /usr/bin/keychain -q --nogui $HOME/.ssh/id_rsa
end
source_exists ~/.keychain/(hostname)-fish

# Colours
source_exists ~/.local/share/nvim/site/pack/packer/start/nightfox.nvim/extra/nightfox/nightfox_fish.fish

### POST ###
source_exists ~/.local/post.fish
