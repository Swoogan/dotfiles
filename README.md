# DOTFILES

My personal config files

## Linux Install

    ln -s ~/dev/dotfiles/_vimrc ~/.vimrc
    ln -s ~/dev/dotfiles/init.vim ~/.config/nvim/init.vim
    ln -s ~/dev/dotfiles/.gitconfig ~/.gitconfig	
    ln -s ~/dev/dotfiles/config.fish ~/.config/fish/config.fish

## Windows Install

    New-SymLink -Link ~/.gitconfig F:\dotfiles\.gitconfig
    New-Symlink -Link ~/Documents\WindowsPowerShell\profile.ps1 F:\dotfiles\profile.ps1
    New-Symlink .vsvimrc F:\dotfiles\_vsvimrc

