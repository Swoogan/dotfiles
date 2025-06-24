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

    winget install Microsoft.Powershell Git.Git neovim rustup zig.zig Microsoft.VisualStudio.2022.BuildTools
    # Run `Visual Studio Installer` and select "Desktop development with C++"
    cargo install fd-find bat ripgrep kanata
    # scoop install git neovim zig fd ripgrep bat
    PowerShellGet\Install-Module posh-git -Scope CurrentUser -Force
    PowerShellGet\Install-Module posh-sshell -Scope CurrentUser

### Configure software

    mkdir ~/AppData/Local/nvim
    mkdir ~/Documents/PowerShell

    # Generate ssh key and upload to githib
    ssh-keygen
    cat ~/.ssh/id_ed25519.pub | Set-Clipboard
    # paste into github

    # Sync dotfiles
    mkdir /dev
    cd /dev
    git clone git@github.com:Swoogan/dotfiles.git

    # In admin console (must manually source profile.ps1)
    . /dev/dotfiles/pwsh/profile.ps1

    $non_admin_home = "???"
    New-SymLink -Link $non_admin_home/.gitconfig C:\dev\dotfiles\git\dot-gitconfig
    New-Symlink -Link $non_admin_home/Documents\PowerShell\profile.ps1 C:\dev\dotfiles\pwsh\profile.ps1
    New-Symlink -Link $non_admin_home/.vsvimrc C:\dev\dotfiles\windows\_vsvimrc
    New-Symlink -Link $non_admin_home\AppData\Local\nvim\init.lua C:\dev\dotfiles\nvim\.config\nvim\init.lua
    New-Symlink -Link $non_admin_home\AppData\Local\nvim\ginit.vim C:\dev\dotfiles\nvim\.config\nvim\ginit.vim
    New-Symlink -Link $non_admin_home\AppData\Local\nvim\lua C:\dev\dotfiles\nvim\.config\nvim\lua
    New-Symlink -Link $non_admin_home\AppData\Local\nvim\lazy-lock.json C:\dev\dotfiles\nvim\.config\nvim\lazy-lock.json

    $compiler = "~\AppData\Local\nvim\compiler"
    if (-not (test-path $compiler)) { mkdir $compiler }
    New-Symlink -Link $compiler\dotnet.vim C:\dev\dotfiles\nvim\.config\nvim\compiler\dotnet.vim

    # this didn't work, just set them manually
    Set-Environment -Name DEV_HOME -Value "C:\dev"
    Set-Environment -Name OMNISHARP -Value "$($env:DEV_HOME)/.ls/omnisharp/OmniSharp.exe"
