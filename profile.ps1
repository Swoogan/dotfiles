Import-Module C:\ProgramData\Chocolatey\lib\psake\tools\psake\psake.psm1

. "$HOME\p5\perforce.ps1"

Start-SshAgent -Quiet

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
    nvim-qt --maximized $HOME/Documents/WindowsPowershell/profile.ps1
}

function Source-Profile {
    . ~/Documents/WindowsPowershell/profile.ps1
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

#######################
### Aliases
#######################

Set-Alias gacutil 'C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6.1 Tools\gacutil.exe'
Set-Alias msbuild "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\MSBuild\15.0\Bin\MSBuild.exe"
Set-Alias ildasm 'C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6.1 Tools\ildasm.exe'
Set-Alias p4mv Move-P4File
Set-Alias p4ren Rename-P4File
Set-Alias touch Set-LastWriteToNow
Set-Alias p5 Invoke-Perforce
Set-Alias p6 Invoke-PeeFive
Set-Alias ep Edit-Profile
Set-Alias spp Source-Profile
Set-Alias ack Find-InFiles
Set-Alias rc Reset-Colors
Set-Alias env Get-Environment
Set-Alias gvm Invoke-NvimQt


$local = "~/.local/profile.ps1"

if (Test-Path $local) {
    . $local
}
