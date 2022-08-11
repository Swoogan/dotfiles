#. "$HOME\p5\p5.ps1"
# . "$HOME\p5\p6.ps1"

$PIT_CONFIG = Join-Path $env:USERPROFILE .pit

function ConvertFrom-UnixTime {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Time
    )

    process {
        Write-Output ([System.DateTimeOffset]::FromUnixTimeSeconds($Time).LocalDateTime)
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

function Add-PitFeature {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Name,
        [Parameter(Mandatory=$false)]
        [switch]$Switch
    )

    process {
        if ($Switch) {
            # Todo: find-unopened should run on the whole depot, or some well known root. However, I do not
            # want to hard-code that root in this file. Might need some kind of pit config file that sets up
            # sub-workspaces for large monorepos, where p4 rec //... is really expensive
            $unopened = Find-UnopenFiles "..."
            if ($null -ne $unopened) {
                Write-Error "There are unopened changes in your workspace. Submit or stash.`n"
                Write-Modifications $unopened
            }
            else {
                # Todo: check for pit directory
                $path = Join-Path $PIT_CONFIG "$Name.feat"
                if (Test-Path $path) {
                    Write-Error "Feature $Name already exists.`n"
                }
                else {
                    New-Item -Path $path
                }
                Set-Content -Path $activeFeatureFile -Value $Name
            }
        }
        else {
            # Todo: check for pit directory
            $path = Join-Path $PIT_CONFIG "$Name.feat"
            if (Test-Path $path) {
                Write-Error "Feature $Name already exists.`n"
            }
            else {
                New-Item -Path $path
                Set-Content -Path $activeFeatureFile -Value $Name
            }
        }
    }
}

function Get-PitActiveFeatureFile {
    [CmdletBinding()]
    param ()

    process {
        $file = Join-Path $PIT_CONFIG "feature"
        Write-Output $file
    }
}

function Get-PitActiveFeature {
    [CmdletBinding()]
    param ()

    process {
        $file = Get-PitActiveFeatureFile
        Get-Content -Path $file
    }
}

function Set-PitActiveFeature {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Name
    )

    process {
        $feat = Join-Path $PIT_CONFIG "$Name.feat"
        if (-not (Test-Path $feat)) { throw "Feature $Name does not exist" }

        $activeFeatureFile = Get-PitActiveFeatureFile
        $active = Get-Content $activeFeatureFile

        if ($active -eq $Name) {
            Write-Warning "Feature $Name is already the active feature."
        }
        else {
            # Todo: find-unopened should run on the whole depot, or some well known root. However, I do not
            # want to hard-code that root in this file. Might need some kind of pit config file that sets up
            # sub-workspaces for large monorepos, where p4 rec //... is really expensive
            $unopened = Find-UnopenFiles "..."
            if ($null -ne $unopened) {
                Write-Error "There are unopened changes in your workspace. Submit or stash.`n"
                Write-Modifications $unopened
            }
            else {
                Set-Content -Path $activeFeatureFile -Value $Name
            }
        }
    }
}

function Get-PitFeature {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, Position=0)]
        [string[]]$Name
    )

    process {
        if ($null -ne $Name) {
            $file = Join-Path $PIT_CONFIG "$Name.feat"
            Get-ChildItem $file | ForEach-Object {
                (Split-Path $_ -leaf) -replace ".feat", ""
            }
        }
        else {
            Get-ChildItem $PIT_CONFIG -Filter *.feat | ForEach-Object {
                (Split-Path $_ -leaf) -replace ".feat", ""
            }
        }
    }
}

function Add-PitFeatureChange {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Name,
        [Parameter(Mandatory=$true, Position=1)]
        [int]$Change
    )

    process {
        # Todo: check for pit directory
        $file = Join-Path $PIT_CONFIG "$Name.feat"
        if (-not (Test-Path $file)) { throw "Feature $Name does not exist" }

        $content = Get-Content $file
        if ($null -eq $content) {
            $changes = @($Change)
        }
        else {
            $changes = $content
            $changes += $Change
        }
        Set-Content -Path $file -Value $changes
    }
}

function Get-PitFeatureChanges {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Name
    )

    process {
        # Todo: check for pit directory
        $file = Join-Path $PIT_CONFIG "$Name.feat"
        if (-not (Test-Path $file)) { throw "Feature $Name does not exist" }

        $content = Get-Content $file
        if ($null -eq $content) {
            $changes = @($Change)
        }
        else {
            $changes = $content
            $changes += $Change
        }

        Write-Output $changes
    }
}

function Remove-PitFeature {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Name
    )

    process {
        $file = Join-Path $PIT_CONFIG "$Name.feat"

        if (-not (Test-Path $file)) { throw "Feature $Name does not exist" }

        # Todo: check for open files, submit state and remove old changelists
        Remove-Item $file
    }
}

function Copy-ShelveToTemp {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [int]$Change,
        [Parameter(Mandatory=$true, Position=1)]
        [string[]]$Files
    )

    process {
        $tmp = Join-Path $env:temp pit
        if (-not (Test-Path $tmp)) { mkdir $tmp | Out-Null }

        # todo: deal with the possiblity that there are multiple files of the same name,
        # but in different directories, within the same changelist
        $diff_temp = Join-Path $tmp $Change
        mkdir $diff_temp | Out-Null

        foreach ($file in $Files) {
            $leaf = Split-Path $file -leaf
            $local = Join-Path $diff_temp $leaf
            p4 print -o $local "$($file.depotFile)@=$Change" | Out-Null
            Write-Output $local
        }
    }
}

function Compare-Files {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$File1,
        [Parameter(Mandatory=$true, Position=1)]
        [string]$File2
    )

    process {
        fc.exe /B $File1 $File2 | Out-Null

        # todo: do a -1,0,1 compare instead of $true/$false?
        Write-Output ($LASTEXITCODE -eq 0)
    }
}

function New-Changelist {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, Position=0)]
        [string]$Message, 
        [Parameter(Mandatory=$false)]
        [switch]$Reopen
    )
    process {
        if ($Reopen) {
            $change = p4 --field "Description=$Message" change -o
        }
        else {
            $change = p4 --field "Description=$Message" --field "Files=" change -o
        }

        $cl = $change | p4 change -i | 
            select-string "\b(\d+)" | 
            ForEach-Object {$_.matches[0].value}

        Write-Output $cl
    }
}

function Find-UnopenFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Path
    )

    $state = @{name="state"; expression={"uo"}}
    $outPath = @{name="path"; expression={$_.clientFile}}

    Invoke-Perforce reconcile -n -m $Path | `
        Where-Object data -eq $null | `
        Select-Object $outPath, $state, action
}

function Get-FilesInChange {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Change,
        [Parameter(Mandatory=$false)]
        [string]$Status,
        [Parameter(Mandatory=$false)]
        [switch]$OnlyOpened
    )

    process {
        # unopened, submitted, shelved, opened => uo, su, sh, op
        $files = @()

        if ($Status -eq "submitted") {
            $files += Invoke-Perforce files "//...@=$Change" | Select-Object action, depotFile, `
                 @{name='state'; expression={"su"}}
        }
        else {
            # load all the non-shelved files
            $files += Invoke-Perforce opened -c $Change | Select-Object action, depotFile, `
                @{name='state'; expression={"op"}}

            # load the shelved files if necessary
            if (-not $OnlyOpened) {
                $files += Invoke-Perforce files "//...@=$Change" | Select-Object action, depotFile, `
                    @{name='state'; expression={"sh"}}
            }
        }

        # find all the local paths for the depot paths
        $where = $files | Select-Object -ExpandProperty depotFile | p4 -ztag -Mj -x - where | ConvertFrom-Json
        $count = $files | Measure-Object | Select-Object -ExpandProperty count

        # Zip the two lists together
        for ($i = 0; $i -lt $count; $i++) { 
            $file = $files[$i]
            $w = $where[$i]     # todo: better variable name
            $depotFile = $w.depotFile -ne $null ? $w.depotFile : $file.depotFile

            $output = [pscustomobject]@{ 
                action = $file.action; 
                state = $file.state; 
                path = $w.path; 
                depotFile = $depotFile; 
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
        if ($Change -eq "default") {
            # TODO: make this a terminating error once converted to a module
            Write-Warning "default changelist cannot be described"
            Exit 1
        }

        $desc = Invoke-Perforce describe $Change
        $onlyOpened = ($desc.shelved -eq $null) -and ($desc.status -ne "submitted")
        $files = Get-FilesInChange $Change -Status $desc.status -OnlyOpened:$onlyOpened

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
            $path = $file.path -ne $null ? $file.path : $file.depotFile
            if ($file.action -eq "add" -or $file.action -eq "move/add") {
                $msg = $fmt -f $prefix,$file.state,$file.action,"    ",$path
                Write-Host -ForegroundColor Yellow $msg
            }
            elseif ($file.action -eq "edit") {
                $msg = $fmt -f $prefix,$file.state,$file.action,"   ",$path
                Write-Host -ForegroundColor Green $msg
            }
            elseif ($file.action -eq "delete" -or $file.action -eq "move/delete") {
                $msg = $fmt -f $prefix,$file.state,$file.action," ",$path
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
                #Invoke-Perforce changes -L -t -s submitted -m 100 -u $user ${__Remaining__} `
                # todo: why does the paging go two lines too far?
                Invoke-Perforce changes -L -t -s submitted -m 100 ${__Remaining__} `
                    | Select-Object change, user, @{name='date';expression={ConvertFrom-UnixTime $_.time}}, desc `
                    | Out-Host -Paging
            }
            "status" {
                # todo: 
                $feature = Get-PitActiveFeature
                Write-Host "On feature " -NoNewline
                Write-Host -ForegroundColor Blue "$feature`n"

                # todo: handle the case of no changes
                $lastFeatureChange = Get-PitFeatureChanges $feature | Select-Object -Last 1

                $opened = Get-FilesInChange default -OnlyOpened
                $count = $opened | Measure-Object | Select-Object -ExpandProperty count

                if ($count -gt 0) {
                    Write-Host "Changes to be submitted:"
                    Write-Host "  (use `"pit restore --staged <file>...`" to unstage)"
                
                    # need to make sure the opened file is in the shelve, then...
                    $opened | ForEach-Object {
                        $local = Copy-ShelveToTemp $lastFeatureChange $_ 
                        $equal = Compare-Files $_.path $local
                        if (-not $equal) {
                            Write-Output $_
                        }
                    } | Write-Modifications -Indent
                }

                Write-Host "Changes not staged for submit:"
                Write-Host "  (use `"pit add <file>...`" to update what will be submitted)"
                #Write-Host "  (use `"pit restore <file>...`" to discard changes in workspace)"
                Find-UnopenFiles "..." | Write-Modifications -Indent

                if ($count -eq 0) {
                    Write-Host "`nno changes added to commit (use `"git add`" and/or `"git commit -a`")"
                }
            }
            "add" {
                Invoke-Perforce reconcile -m ${__Remaining__} | Where-Object data -eq $null | Out-Null
            }
            "submit" {
                $opened = Get-FilesInChange default
                $count = $opened | Measure-Object | Select-Object -ExpandProperty count

                if ($count -eq 0) {
                    # Note: git just does a git status and exits
                    Write-Error "No files have been staged for commit"
                    Write-Error "  (use `"pit add <file>...`" to update what will be submitted)"
                }
                else {
                    $message = ${__Remaining__}[0]
                    $cl = New-Changelist -Reopen $message
                    p4 shelve -f -c $cl | Out-Null
                    # Shelving files for change 37504.
                    # add //hvn/games/bleep/game/Plugins/DiffAssets/Content/WritePermissions.B9C10A2E466CC3FD4203ECAC8F85A9FB.temp#1
                    # Change 37504 files shelved.
                    
                    p4 revert -k -c $cl //...
                    # todo: should Add-PitFeatureChange just always use the current feature?
                    $feat = Get-PitActiveFeature
                    Add-PitFeatureChange -Name $feat -Change $cl
                    
                    Write-Host "[$feat $cl] $message"
                    #Write-Host " $countChanged file(s) changed..."
                }
            }
            "pending" {
                Invoke-Perforce changes -L -u $user -s pending -c $client ${__Remaining__} | Select-Object change, desc
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
                Get-FilesInChange default -OnlyOpened | Write-Modifications -Indent

                $pending = Invoke-Perforce changes -L -u $user -s pending -c $client ${__Remaining__}
                foreach ($cl in $pending) {
                    Write-Host "[$($cl.change)] $($cl.desc)"
                    $desc = Get-ChangeDescription $cl.change
                    Write-Modifications $desc.Files -Indent
                }

                Write-Host "[unopened]`n"
                Find-UnopenFiles "..." | Write-Modifications -Indent
                
                # Find new New-Changelists
                $latest = Invoke-Perforce changes -m1 "@$client" | Select-Object -ExpandProperty change
                # Note, using p4 instead of Invoke-Perforce because of issue with `-e` being ambiguous
                $changes = p4 -ztag -Mj changes -e $latest -s submitted | ConvertFrom-Json | `
                    Select-Object -ExpandProperty change -SkipLast 1
                $count = $changes | Measure-Object | Select-Object -ExpandProperty count

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

                # Todo: this will get open files, which may be a bug
                $files = Get-FilesInChange $diff_cl -Status "pending"

                foreach ($file in $files) {
                    $leaf = Split-Path $file.path -leaf
                    $local = Join-Path $diff_temp $leaf
                    p4 print -o $local "$($file.depotFile)@=$diff_cl" | Out-Null
                    git diff --no-index $local $file.path	
                }

                Remove-Item -Recurse -Force $diff_temp | Out-Null
            }
            "du" { # diff unopened
                $tmp = Join-Path $env:temp pit
                if (-not (Test-Path $tmp)) { mkdir $tmp | Out-Null }

                $diff_temp = Join-Path $tmp "have.$(Get-Random -Maximum 10000)"
                mkdir $diff_temp | Out-Null

                $files = Invoke-Perforce reconcile -n -m ... | Where-Object data -eq $null
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

                Remove-Item -Recurse -Force $diff_temp | Out-Null
            }
            "update" {
                Write-Host "Gathering Changelists to sync..."

                $latest = Invoke-Perforce changes -m1 "@$client" | Select-Object -ExpandProperty change
                # Note, using p4 instead of Invoke-Perforce because of issue with `-e` being ambiguous
                #$changes = p4 -ztag -Mj changes -e $latest -s submitted "@$client" | ConvertFrom-Json | `
                $changes = p4 -ztag -Mj changes -e $latest -s submitted | ConvertFrom-Json | `
                    Select-Object -ExpandProperty change -SkipLast 1 | Sort-Object
                $count = $changes | Measure-Object | Select-Object -ExpandProperty count

                if ($count -eq 0) {
                    Write-Host "Already up to date."
                }
                else {
                    Invoke-Perforce update | Select-Object action, `
                        @{name='path';expression={$_.clientFile}}, @{name='revision';expression={$_.rev}} | `
                        Out-Host -Paging
                }
            }
            "bu" { # better update?

                Write-Host "Gathering Changelists to sync..."
                $latest = Invoke-Perforce changes -m1 "@$client" | Select-Object -ExpandProperty change
                # Note, using p4 instead of Invoke-Perforce because of issue with `-e` being ambiguous
                $changes = p4 -ztag -Mj changes -e $latest -s submitted | ConvertFrom-Json | `
                    Select-Object -ExpandProperty change -SkipLast 1 | Sort-Object
                $count = $changes | Measure-Object | Select-Object -ExpandProperty count

                if ($count -eq 0) {
                    Write-Host "Already up to date."
                    Exit 0
                }

                Write-Host ("Updating {0}..{1}" -f $changes[0], $changes[-1])

                for ($i = 1; $i -le $count; $i++) { 
                    $change = $changes[$i-1]
                    $percent = ($i/$count) * 100
                    
                    # Write-Host $percent
                    Write-Progress -Activity "Updating" -Status "Syncing $change..." -PercentComplete $percent

                    pit sync "//...@$change" | Select-Object action, `
                         @{name='path';expression={$_.clientFile}}, @{name='revision';expression={$_.rev}} | `
                         # Out-Host -Paging
                         Out-Null
                }
            }
            "fs" { # File-based syncing (might be faster in some instances, needs more testing)

                Write-Host "Gathering Changelists to sync..."
                $latest = Invoke-Perforce changes -m1 "@$client" | Select-Object -ExpandProperty change
                # Note, using p4 instead of Invoke-Perforce because of issue with `-e` being ambiguous
                $changes = p4 -ztag -Mj changes -e $latest -s submitted | ConvertFrom-Json | `
                    Select-Object -ExpandProperty change -SkipLast 1 | Sort-Object
                $count = $changes | Measure-Object | Select-Object -ExpandProperty count

                if ($count -eq 0) {
                    Write-Host "Already up to date."
                    Exit 0
                }

                Write-Host ("Updating {0}..{1}" -f $changes[0], $changes[-1])

                for ($i = 1; $i -le $count; $i++) { 
                    $change = $changes[$i-1]
                    $percent = ($i/$count) * 100
                    
                    # Write-Host $percent
                    Write-Progress -Activity "Updating" -Status "Syncing $change..." -PercentComplete $percent

                    $files = Get-FilesInChange $change -Status "submitted"
                    $fileCount = $files | Measure-Object | Select-Object -ExpandProperty count

                    Write-Host "Syncing $fileCount files..."

                    $files | ForEach-Object { "{0}@{1}" -f $_.depotFile, $change } | p4 -ztag -Mj -x - sync | `
                        ConvertFrom-Json | Out-Host -Paging
                }
            }
            "help" {
                p4 help ${__Remaining__}
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
