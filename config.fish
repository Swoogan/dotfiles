if test -z (pgrep ssh-agent)
  eval (ssh-agent -c)
  set -Ux SSH_AUTH_SOCK $SSH_AUTH_SOCK
  set -Ux SSH_AGENT_PID $SSH_AGENT_PID
  set -Ux SSH_AUTH_SOCK $SSH_AUTH_SOCK
end

source ~/.local/config.fish

set -gx WASMTIME_HOME "$HOME/.wasmtime"

# Wasmer config
set WASMER_DIR "$HOME/.wasmer"
set -gx WASMER_CACHE_DIR "$WASMER_DIR/cache"

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ls='exa'
alias ll='exa --long'
alias lg='exa --long --git'
