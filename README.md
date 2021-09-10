# DOTFILES

My personal config files

Install 

## Linux Install

    ln -s ~/dev/dotfiles/init.lua ~/.config/nvim/init.lua
    ln -s ~/dev/dotfiles/.gitconfig ~/.gitconfig	
    ln -s ~/dev/dotfiles/config.fish ~/.config/fish/config.fish

## Windows Install
 
### Install choco

    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

### Install software

    choco install -y git neovim
    PowerShellGet\Install-Module posh-git -Scope CurrentUser -Force
    PowerShellGet\Install-Module posh-sshell -Scope CurrentUser

### Configure software

    mkdir ~/AppData/Local/nvim

    # install vim plug
    iwr -useb https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim |`
        ni "$(@($env:XDG_DATA_HOME, $env:LOCALAPPDATA)[$null -eq $env:XDG_DATA_HOME])/nvim-data/site/autoload/plug.vim" -Force

    New-SymLink -Link ~/.gitconfig C:\dev\dotfiles\gitconfig
    New-Symlink -Link ~/Documents\PowerShell\profile.ps1 C:\dev\dotfiles\profile.ps1
    New-Symlink -Link ~/.vsvimrc C:\dev\dotfiles\_vsvimrc
    New-Symlink -Link ~\AppData\Local\nvim\init.lua C:\dev\dotfiles\init.lua

