#. "$HOME\p5\p5.ps1"
# . "$HOME\p5\p6.ps1"

function ConvertFrom-UnixTime {
    param ([string]$time)

    Write-Output ([System.DateTimeOffset]::FromUnixTimeSeconds($time).LocalDateTime)
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

function New-Changelist {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$Message
    )
    process {
        $cl = p4 --field "Description=$Message" --field "Files=" change -o | 
            p4 change -i | 
            select-string "\b(\d+)" | 
            ForEach-Object {$_.matches[0].value}

        Write-Output $cl
    }
}

function Get-FilesInChange {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Change,
        [Parameter(Mandatory=$false)]
        [switch]$Shelve
    )

    process {
        $files = @()

        # load all the non-shelved files
        $files += Invoke-Perforce opened -c $Change | select action, depotFile, `
             @{name='state'; expression={"o"}}

        # load the shelved files if necessary
        if ($Shelve) {
            $files += Invoke-Perforce files "//...@=$Change" | select action, depotFile, `
                 @{name='state'; expression={"s"}}
        }

        # find all the local paths for the depot paths
        $where = $files | select -ExpandProperty depotFile | p4 -ztag -Mj -x - where | ConvertFrom-Json

        # Zip the two lists together
        for ($i = 0; $i -lt $files.Length; $i++) { 
            $output = [pscustomobject]@{ 
                action = $files[$i].action; 
                state = $files[$i].state; 
                path = $where[$i].path; 
                depotFile = $where[$i].depotFile; 
            }

            Write-Output $output
        } 
    }
}

function Get-ChangeDescription {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Change
    )

    process {
        $desc = Invoke-Perforce describe $Change
        $shelved = $desc.shelved -ne $null
        $files = Get-FilesInChange $Change -Shelve:$shelved

        $output = [pscustomobject]@{
            Change = $desc.change;
            Description = $desc.desc;
            Status = $desc.status;
            Date = ConvertFrom-UnixTime $desc.time;
            Author = $desc.user;
            Files = $files;
        }

        Write-Output $output
    } 
}

function Write-Modifications {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline)]
        [object[]]$Files,
        [Parameter(Mandatory=$false)]
        [switch]$Indent
    )

    process {
                #Write-Host -ForegroundColor Yellow "$prefix[$($file.state)][add]    $($file.path)"
        $fmt = "{0}[{1}] [{2}]{3} {4}"
        $prefix = $Indent ? "`t" : ""

        foreach ($file in $Files) {
            if ($file.action -eq "add") {
                $msg = $fmt -f $prefix,$file.state,$file.action,"    ",$file.path
                Write-Host -ForegroundColor Yellow $msg
            }
            elseif ($file.action -eq "edit") {
                $msg = $fmt -f $prefix,$file.state,$file.action,"   ",$file.path
                Write-Host -ForegroundColor Green $msg
            }
            elseif ($file.action -eq "delete") {
                $msg = $fmt -f $prefix,$file.state,$file.action," ",$file.path
                Write-Host -ForegroundColor Red $msg
            }
        }
    }

    end {
        Write-Host ""
    }
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

        # Todo: check to see if user is logged in

        switch (${__Command__}) {
            "log" {
                Invoke-Perforce changes -L -t -s submitted -m 100 -u $user ${__Remaining__} `
                    | select change, @{name='date';expression={ConvertFrom-UnixTime $_.time}}, desc
                    | more
            }   
            "pending" {
                Invoke-Perforce changes -L -u $user -s pending -c $client ${__Remaining__} | select change, desc
            }
            "describe" {
                $desc = Get-ChangeDescription ${__Remaining__}
                Write-Host -ForegroundColor Yellow "change $($desc.Change)"
                Write-Host "Author: $($desc.Author)"
                Write-Host "Date: $($desc.Date)"
                Write-Host "Status: $($desc.Status)"
                Write-Host "`n`t$($desc.Description)"

                Write-Modifications $desc.Files
            }
            "state" {
                Write-Host "`n[default]`n"
                Get-FilesInChange default | Write-Modifications -Indent

                # TODO: might need a way to display whether the files are shelved or not
                $pending = Invoke-Perforce changes -L -u $user -s pending -c $client ${__Remaining__}
                foreach ($cl in $pending) {
                    Write-Host "[$($cl.change)] $($cl.desc)"
                    $desc = Get-ChangeDescription $cl.change
                    Write-Modifications $desc.Files -Indent
                }

                Write-Host "[unopened]`n"
                $state = @{name="state"; expression={"u"}}
                Invoke-Perforce reconcile -n ... | `
                    select @{name="path"; expression={$_.clientFile}}, $state, action | `
                    Write-Modifications -Indent
                
                # Find new New-Changelists
                $count = Invoke-Perforce cstat | where status -eq "need" | Measure-Object | select -ExpandProperty Count
                if ($count -gt 1) {
                    Write-Warning "Your workspace is $count submits behind the depot."
                }
                elseif ($count -gt 0) {
                    Write-Warning "Your workspace is $count submit behind the depot."
                }
            }
            "new" {
                $cl = New-Changelist ${__Remaining__}[0]
                $env:PIT_CHANGE = $cl
                Write-Output $cl
            }
            "ds" { # diff shelve
                $tmp = Join-Path $env:temp pit
                if (-not (Test-Path $tmp)) { mkdir $tmp | Out-Null }

                $diff_cl = ${__Remaining__}[0]
                $diff_temp = Join-Path $tmp $diff_cl
                mkdir $diff_temp | Out-Null

                $files = Get-FilesInChange $diff_cl -Shelve

                foreach ($file in $files) {
                    $leaf = Split-Path $file.path -leaf
                    $local = Join-Path $diff_temp $leaf
                    p4 print -o $local "$($file.depotFile)@=$diff_cl" | Out-Null
                    git diff --no-index $local $file.path	
                }

                rm -Recurse -Force $diff_temp | Out-Null
            }
            "du" { # diff unopened
                $tmp = Join-Path $env:temp pit
                if (-not (Test-Path $tmp)) { mkdir $tmp | Out-Null }

                $diff_temp = Join-Path $tmp "have.$(Get-Random -Maximum 10000)"
                mkdir $diff_temp | Out-Null

                $files = Invoke-Perforce reconcile -n -m ... | ? data -eq $null
                Write-Host $files

                foreach ($file in $files) {
                    if ($file.action -eq "edit") {
                        $leaf = Split-Path $file.clientFile -leaf
                        $local = Join-Path $diff_temp $leaf
                        Write-Host $local
                        p4 print -o $local "$($file.depotFile)#have" | Out-Null
                        git diff --no-index $local $file.clientFile	
                    }
                    else {
                        Write-Modifications $file
                    }
                }

                rm -Recurse -Force $diff_temp | Out-Null
            }
            # todo
            # shelve, unshelve, stash, stash list, stash pop
            default {
                Invoke-Perforce ${__Command__} ${__Remaining__}
            }
        }
    }
}


# function Find-Config {
#     $root = $(Resolve-Path .).Drive.Root
#     $cwd = "."
#
#     while ($true) {
#         $path = Resolve-Path $cwd
#         if (Test-Path "$path/.p5") {
#             $config = Resolve-Path "$path/.p5"
#             Write-Output $config
#             break
#         }
#         elseif ($root -eq $path.Path) {
#             break
#         }
#         else {
#             $cwd += "/.."
#         }
#     }
# }
