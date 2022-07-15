if ($HOST.Name -eq "Package Manager Host") {
    exit 0
}

Import-Module Posh-Git
Import-Module posh-p4

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

# . "$HOME\p5\perforce.ps1"

if ($host.Name -eq 'ConsoleHost') {
    Import-Module PSReadLine
    # Delete from the cursor to the beginning of the line
    Set-PSReadlineKeyHandler -Key Ctrl+U -Function BackwardDeleteLine
    # Delete from the cursor to the end of the line
    Set-PSReadlineKeyHandler -Key Ctrl+K -Function ForwardDeleteLine
    # Bash style tab completion
    Set-PSReadlineKeyHandler -Key Tab -Function Complete

    # Ctrl-D will exit
    Set-PSReadlineKeyHandler -Key Ctrl+d `
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

function Set-Environment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string] $Name, 
        [Parameter(Mandatory=$true, Position=1)]
        [string] $Value
    )

    Set-Item "`env:\$Name" $Value
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
    nvim-qt --maximized $HOME/Documents/Powershell/profile.ps1
}

function Source-Profile {
    . ~/Documents/Powershell/profile.ps1
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
    Remove-Item -Recurse -Force 
}

function Set-Development ([string]$location) {
    Set-Location $Env:DEV_HOME
    if ($location) {
        Set-Location $location
    }
}

function Invoke-Perforce {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromRemainingArguments=$true)]
        ${__Remaining__}
    )

    process {
        p4 -Ztag -Mj ${__Remaining__} | ConvertFrom-Json
    }
}

function ConvertFrom-UnixTime {
    param ([string]$time)

    Write-Output ([System.DateTimeOffset]::FromUnixTimeSeconds($time).LocalDateTime)
}

function Invoke-Pit {
    [CmdletBinding()]
    param (
        # Command. I use two underscores so that variable shortener won't steal switches I'm trying to pass to ${__Remaining__}
        [Parameter(Mandatory=$true, Position=0)]
        [string] ${__Command__}, 
        [Parameter(Mandatory=$false, Position=1, ValueFromRemainingArguments=$true)]
        ${__Remaining__}
    )

    process {
        $info = Invoke-Perforce info
        # todo: cache this info somehow
        $client = $info.clientName
        $user = $info.userName

        switch (${__Command__}) {
            "log" {
                Invoke-Perforce changes -L -t -s submitted -m 100 -u $user ${__Remaining__} `
                    | select change, @{name='date';expression={ConvertFrom-UnixTime $_.time}}, desc
                    | more
            }   
            # todo
            # shelve, unshelve, stash, stash list, stash pop
            default {
                Invoke-Perforce ${__Command__} ${__Remaining__}
            }
        }
    }
}


#######################
### Aliases
#######################

Set-Alias touch Set-LastWriteToNow
Set-Alias pit Invoke-Pit
Set-Alias ep Edit-Profile
Set-Alias spp Source-Profile
Set-Alias rc Reset-Colors
Set-Alias env Get-Environment
Set-Alias rmr Remove-ItemsRecursive
Set-Alias dev Set-Development
Set-Alias ll Get-ChildItem

#######################
### Variables
#######################
Set-Item -Path Env:DEV_HOME -Value "C:\dev"
Set-Item -Path Env:OMNISHARP -Value "$($Env:DEV_HOME)/.ls/omnisharp/OmniSharp.exe"

$local = "~/.local/profile.ps1"

if (Test-Path $local) {
    . $local
}
