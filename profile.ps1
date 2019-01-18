Import-Module C:\ProgramData\Chocolatey\lib\psake\tools\psake\psake.psm1
Import-Module posh-git

Start-SshAgent -Quiet

if ($host.Name -eq 'ConsoleHost') {
    Import-Module PSReadLine
    Set-PSReadlineKeyHandler -Key Ctrl+U -Function BackwardDeleteLine
    Set-PSReadlineKeyHandler -Key Ctrl+K -Function ForwardDeleteLine
    Set-PSReadlineKeyHandler -Key Tab -Function Complete

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

function Edit-Profile {
    gvim ~/Documents/WindowsPowershell/profile.ps1
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

##############
# Perforce
##############

# TODO: Move to module

function Move-P4File ([string]$Path, [string]$Destination) {
    p4 edit $Path
    Get-ChildItem $Path | ForEach-Object { p4 move $_.FullName ("{0}\{1}" -f $Destination, $_.Name)}
}

function Rename-P4File ([string]$Path, [string]$Destination) {
    p4 edit $Path

    foreach ($file in $(Get-ChildItem $Path)) {
        $fn = $file.Name
        $slash = $fn.IndexOf("\")
        [int]$dot
        if ($slash -ne -1) {
            $dot = $fn.IndexOf(".", $slash)
        } else {
            $dot = $fn.IndexOf(".")
        }
        $tail = $fn.Substring($dot)
        p4 move $fn (".\{0}{1}" -f $Destination, $tail)
    }
}

function New-Changelist {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$Message
    )
    process {
        $cl = $(p4 change -o) -replace "<enter description here>", $Message -replace "\s*//.*$", "" | 
            p4 change -i | 
            select-string "\b(\d+)" | 
            ForEach-Object {$_.matches[0].value}

        Write-Output $cl
    }
}

function Find-Config {
    $root = $(Resolve-Path .).Drive.Root
    $cwd = "."

    while ($true) {
        $path = Resolve-Path $cwd
        if (Test-Path "$path/.p5") {
            $config = Resolve-Path "$path/.p5"
            Write-Output $config
            break
        }
        elseif ($root -eq $path.Path) {
            break
        }
        else {
            $cwd += "/.."
        }
    }
}

function Invoke-Perforce {
    [CmdletBinding()]
    param (
        # Command. I use three underscores so that variable shorten won't still switches I'm trying to pass to ${__Remaining__}
        [Parameter(Mandatory=$true, Position=0)]
        [string] ${__Command__}, 
        [Parameter(Mandatory=$false, Position=1, ValueFromRemainingArguments=$true)]
        ${__Remaining__}
    )
	
    process {
		$client = $(p4 -Ztag -F %clientName% info)
		
		switch (${__Command__}) {
			"stash" {
				$cl = New-Changelist
				p4 reopen -c $cl ./...
				p4 shelve -f -c $cl ./...
				p4 revert -w ./...
			}
			"stash-list" {
				p4 changes -s shelved -u $Env:Username -c $client
			}
			"log" {
				p4 changes -L -t -s submitted -u $Env:Username -c $client ${__Remaining__} | more
			}        
			"pending" {
				p4 changes -u $Env:Username -s pending ${__Remaining__}
			}
			"local-pending" {
				p4 changes -u $Env:Username -s pending -c $client ${__Remaining__}
			}
			"shelved" {
				p4 changes -u $Env:Username -s shelved ${__Remaining__}
			}
			"local-shelved" {
				p4 changes -u $Env:Username -s shelved -c $client ${__Remaining__}
			}
			"unshelve" {
				# see if ${__Remaining__} has lenth >= 1
				p4 unshelve -s ${__Remaining__}[0] -f -c ${__Remaining__}[0] ${__Remaining__}[1..${__Remaining__}.Length]
				p4 shelve -d -c ${__Remaining__}[0]
			}
			"shelve" {
				p4 shelve -f -c ${__Remaining__}[0]
				p4 revert -w -c ${__Remaining__}[0] ./...
			}
			"new" {
				$cl = $(p4 change -o) -replace "<enter description here>", ${__Remaining__}[0] -replace "\s*//.*$", "" | p4 change -i | select-string "\b(\d+)" | ForEach-Object {$_.matches[0].value}
				Write-Output $cl
			}
			"reopen" {
				p4 -F %depotFile% opened -c default | p4 -x - reopen -c ${__Remaining__}[0]
			}
            "ud" { # Update description
                p4 --field Description="${__Remaining__}[1]" change -o ${__Remaining__}[0] | p4 change -i
            }
            "status" {
                $cls = p4 -z tag -F %change% changes -u $Env:Username -s pending -c $client 
                foreach ($cl in $cls) {
                    Write-Output "`n Changelist $cl`n"
                    $files = p4 -z tag -F "%action%:`t%localFile%" status
                    $files | % { Write-Output "`t$_" }
                }
                Write-Output ""
            }
            "branch" {
                $config = "(Find-Config)/config"
                if (Test-Path $config) {
                    . $config
                }

                $branchName = ${__Remaining__}[0]

                # create branch mapping (TODO move to cmdlet for reuse?)
                $branchSpec = p4 --field View="$main/... $branches/$branchName/..." branch -o "$branchNameRoot$branchName"
                $branchSpec | p4 branch -i

                # create a client
                $clientSpec = p4 `
                    --field View="$branches/$branchName/... //$wsNameRoot$branchName/..." `
                    --field Root="$branchesRoot\$branchName" `
                    --field Options="allwrite clobber nocompress unlocked nomodtime normdir" `
                    client -o "$wsNameRoot$branchName"

                $clientSpec | p4 client -i
                p4 populate -b "$branchNameRoot$branchName"
                p4 set P4CLIENT="$wsNameRoot$branchName"
            }
            "checkout" {
                $config = Find-Config
                if (Test-Path $config) {
                    . $config
                }

                # p4 populate
                # p4 client -i 
                # p4 branch -i
                # store jira
                
            }
			default {
				p4 ${__Command__} ${__Remaining__}
			}
        }
    }
}

##############

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
Set-Alias msbuild "C:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe"
#Set-Alias msbuild "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\MSBuild\15.0\Bin\msbuild.exe"
Set-Alias ildasm 'C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6.1 Tools\ildasm.exe'
Set-Alias p4mv Move-P4File
Set-Alias p4ren Rename-P4File
Set-Alias touch Set-LastWriteToNow
Set-Alias p5 Invoke-Perforce
Set-Alias ep Edit-Profile
Set-Alias ack Find-InFiles

$local = "~/.local/profile.ps1"

if (Test-Path $local) {
	. $local
}
