# DOTFILES

My personal config files

## Linux Install

    ln -s ~/source/_vimrc ~/.vimrc
    ln -s ~/source/_vimrc ~/.config/nvim/init.vim
    ln -s dev/dotfiles/.gitconfig ~/.gitconfig	

## Windows Install

    New-SymLink -Link ~/.gitconfig F:\dotfiles\.gitconfig
    New-Symlink -Link ~/Documents\WindowsPowerShell\profile.ps1 F:\dotfiles\profile.ps1
    New-Symlink .vsvimrc F:\dotfiles\_vsvimrc

