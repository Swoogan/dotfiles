# DOTFILES

My personal config files

Install 

## Linux Install

    set -x STOW_DIR "$DEV_HOME/dotfiles"
    stow --dotfiles -v -t ~ stow

    stow --ignore="dot-.*" fish
    stow --ignore="dot-.*" nvim
    stow --dotfiles -S git

## Windows Install
 
### Install scoop

    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; irm get.scoop.sh | iex

### Install software

    scoop install git neovim zig fd ripgrep bat
    PowerShellGet\Install-Module posh-git -Scope CurrentUser -Force
    PowerShellGet\Install-Module posh-sshell -Scope CurrentUser

### Configure software

    mkdir ~/AppData/Local/nvim
    mkdir ~/Documents/PowerShell

    # In admin console (must manually source profile.ps1)

    New-SymLink -Link ~/.gitconfig C:\dev\dotfiles\git\dot-gitconfig
    New-Symlink -Link ~/Documents\PowerShell\profile.ps1 C:\dev\dotfiles\pwsh\profile.ps1
    New-Symlink -Link ~/.vsvimrc C:\dev\dotfiles\windows\_vsvimrc
    New-Symlink -Link ~\AppData\Local\nvim\init.lua C:\dev\dotfiles\nvim\.config\nvim\init.lua

    $compiler = "~\AppData\Local\nvim\compiler"
    if (-not (test-path $compiler)) { mkdir $compiler }
    New-Symlink -Link $compiler\dotnet.vim C:\dev\dotfiles\nvim\.config\nvim\compiler\dotnet.vim

    Set-Environment -Name DEV_HOME -Value "C:\dev"
    Set-Environment -Name OMNISHARP -Value "$($env:DEV_HOME)/.ls/omnisharp/OmniSharp.exe"
