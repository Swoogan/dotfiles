if ($HOST.Name -eq "Package Manager Host") {
    exit 0
}

# The default style, Minimal, is broken on Windows Terminal.
# Revert to the classic style until they fix it (lol, like that will happen)
if ($null -ne $env:WT_SESSION) {
    $PSStyle.Progress.View = "Classic"
}

#
# another prompt sample
# posh-p4 enabled, posh-git enabled and current folder in window's top bar
#
#function global:prompt {
#
#    $realLASTEXITCODE = $LASTEXITCODE
#
#    #perforce status
#    Write-P4Prompt
#
#    #git status
#    Write-VcsStatus
#
#    $global:LASTEXITCODE = $realLASTEXITCODE
#
#    #override window title with current folder
#    $Host.UI.RawUI.WindowTitle = "$pwd - Windows Powershell"
#
#    return "$ "
#}


if ($host.Name -eq 'ConsoleHost') {
    # Delete from the cursor to the beginning of the line
    Set-PSReadlineKeyHandler -Chord "Ctrl+u" -Function BackwardDeleteLine
    # Delete from the cursor to the end of the line
    Set-PSReadlineKeyHandler -Chord "Ctrl+k" -Function ForwardDeleteLine
    # Accepts the next suggested word
    Set-PSReadLineKeyHandler -Chord "Alt+f" -Function ForwardWord
    # Accepts the next suggested word
    Set-PSReadLineKeyHandler -Chord "Ctrl+f" -Function AcceptSuggestion
    # Bash style tab completion
    Set-PSReadlineKeyHandler -Key Tab -Function Complete

    # Ctrl-D will exit
    Set-PSReadlineKeyHandler -Chord "Ctrl+d" `
    -BriefDescription "Exit" `
    -LongDescription "Exit" `
    -ScriptBlock {
        param($key, $arg)
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert('exit')
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
}

function Set-LastWriteToNow { 
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline=$true)]
        [string[]]$Path
    )
    
    process {
        foreach ($p in $Path) {
            if (-not (Test-Path $p)) {
                New-Item $p | Out-Null
            } else {
                $file = Get-ChildItem $p
                    $file.LastWriteTime = [datetime]::Now 
            }
        }
    }
}

function New-Symlink {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Link,
        [Parameter(Mandatory=$true)]
        [string]$Target
    )
    
    process {
        New-Item -Path $Link -ItemType SymbolicLink -Value $Target
    }
}

function Find-InFiles([string]$Pattern, [string]$Filter) {
     Get-ChildItem -Recurse $Filter | Select-String $Pattern -List | Select-Object path
}

function Get-Environment {
    Get-ChildItem env:\
}

function Get-Path {
    Get-Environment | Where-Object name -eq path | Select-Object -ExpandProperty value | ForEach-Object { $_ -split ";" }
}

function Set-Environment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Name, 
        [Parameter(Mandatory=$true, Position=1)]
        [string] $Value
    )

    Set-Item "env:\$Name" $Value
    [System.Environment]::SetEnvironmentVariable($Name, $Value, [System.EnvironmentVariableTarget]::Machine)
}

function Invoke-NvimQt {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, Position=0, ValueFromRemainingArguments=$true)]
        ${__Remaining__}
    )
    
    nvim-qt --maximized ${__Remaining__}
}

function Edit-Profile {
    nvim $HOME/Documents/Powershell/profile.ps1
}

function Read-Profile {
    . ~/Documents/Powershell/profile.ps1
}

function New-TestPrompt {
    pwsh -NoLogo -NoExit -Command { function Prompt { "$($executionContext.SessionState.Path.CurrentLocation) (test)$('> ')" } }
}

function Get-AuthHeader {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$User,
        [Parameter(Mandatory = $true)]
        [string]$Password
    )
    
    process {
        $pair = "${user}:${pass}"

        $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
        $base64 = [System.Convert]::ToBase64String($bytes)

        $basicAuthValue = "Basic $base64"

        $header = @{ Authorization = $basicAuthValue }
        Write-Output $header
    }
}

function Reset-Colors {
    [System.Console]::ResetColor()
}
    
function Invoke-BinaryProcess([string]$processName, [string]$arguments) {
    $processStartInfo = New-Object System.Diagnostics.ProcessStartInfo 
    $processStartInfo.FileName = $processName
    $processStartInfo.WorkingDirectory = (Get-Location).Path 
    if($arguments) { $processStartInfo.Arguments = $arguments } 
    $processStartInfo.UseShellExecute = $false 
    $processStartInfo.RedirectStandardOutput = $true

    $process = [System.Diagnostics.Process]::Start($processStartInfo) 
    $process.WaitForExit() 
    $process.StandardOutput.ReadToEnd()
}

function Remove-ItemsRecursive {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    Remove-Item -Recurse -Force -Path $Path
}

function Set-Development ([string]$location) {
    Set-Location $Env:DEV_HOME
    if ($location) {
        Set-Location $location
    }
}

function Edit-Line {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline)]
        [string[]]
        $Line
    )

    process {
        $lastIndex = $Line.LastIndexOf(":")
        $path = $Line.Substring(0, $lastIndex)
        $path = Get-ChildItem $path | Select-Object -ExpandProperty FullName # normalize the path
        $lineNbr = $Line.Substring($lastIndex + 1)
        nvim $path "+$lineNbr"
    }
}

function Edit-All {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline)]
        [string]
        $InputObject
    )

    process {
        nvim $InputObject
    }
}

function Select-RuffFiles {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline)]
        [string]
        $InputObject,
        [string]
        $SkipLast = 1
    )

    begin {
        $allInputs = @()
    }

    process {
        $allInputs += $InputObject
    }

    end {
        $allInputs | Select-Object -SkipLast $SkipLast | ForEach-Object {
            $_ -split ":" | Select-Object -First 1 
        } | Sort-Object -Unique | Write-Output
    }
}

#######################
### Aliases
#######################

Set-Alias touch Set-LastWriteToNow
Set-Alias ep Edit-Profile
Set-Alias spp Read-Profile
Set-Alias rc Reset-Colors
Set-Alias env Get-Environment
Set-Alias path Get-Path
Set-Alias rmr Remove-ItemsRecursive
Set-Alias dev Set-Development
Set-Alias ll Get-ChildItem

#######################
### Variables
#######################
# Set-Item -Path Env:SOME_VAR -Value ""

$local = "~/.local/profile.ps1"

if (Test-Path $local) {
    . $local
}

$perforce = "$($Env:DEV_HOME)\dotfiles\perforce\perforce.ps1"
if (Test-Path $perforce) {
    . $perforce
}

$PSStyle.FileInfo.Directory = "`e[34m"
