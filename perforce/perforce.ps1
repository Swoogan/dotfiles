$PIT_CONFIG = Join-Path $env:USERPROFILE .pit
$DEFAULT_FEATURE = "depot"

<#
1..20 | foreach -Begin { Write-Host "$e[s" -NoNewline} -Process {
    Write-Host "$e[u$("▉"*$_)" -NoNewLine; Start-Sleep -MilliSeconds 100
}
#>
enum FileState {
    Open
    Unopen
    Shelved
    Submitted
}

class PitFile {
    [string]$Path
    [string]$DepotFile
    # todo: make this an enum
    [string]$Action
    [FileState]$State
}

# $file = [PitFile]::new()

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

function Get-PerforceTicket {
    [CmdletBinding()]
    param ()

    process {
        $tickets = p4 tickets
        $tickets | ForEach-Object { 
            $record = $_ -split " "; 
            $name = $record[1].SubString(1,$record[1].Length-2); 
            [pscustomobject]@{ user = $name; ticket = $record[2] } 
        }
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
        if (-not (Test-Path $PIT_CONFIG)) { mkdir $PIT_CONFIG | Out-Null }

        $path = Join-Path $PIT_CONFIG "$Name.feat"
        if (Test-Path $path) {
            Write-Error "Feature '$Name' already exists.`n"
        }
        else {
            $data = [pscustomobject]@{changes = @(); review = $null }
            $json = ConvertTo-Json $data
            Set-Content -Path $path -Value $json
        }

        if ($Switch) {
            Set-PitActiveFeature $Name
        }
    }
}

function Get-PitActiveFeatureFile {
    [CmdletBinding()]
    param ()

    process {
        if (-not (Test-Path $PIT_CONFIG)) { mkdir $PIT_CONFIG | Out-Null }
        $file = Join-Path $PIT_CONFIG "feature"
        if (-not (Test-Path $file)) { throw "No active feature current specified" }
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
        if (-not (Test-Path $PIT_CONFIG)) { mkdir $PIT_CONFIG | Out-Null }

        $feat = Join-Path $PIT_CONFIG "$Name.feat"
        if (($Name -ne $DEFAULT_FEATURE) -and (-not (Test-Path $feat))) { throw "Feature '$Name' does not exist" }

        $active = Get-PitActiveFeature

        if ($active -eq $Name) {
            Write-Warning "Feature '$Name' is already the active feature."
            return
        }
 
        # Todo: implement nowrite workflow

        $opened = Invoke-Perforce opened
        $openedDelta = $opened | Select-DiffersFromDepot
        $openChanged = $openedDelta | Measure-Object | Select-Object -ExpandProperty count

        if ($openChanged -gt 0) {
            Write-Host -ForegroundColor Red "Your workspace has modified files, submit, checkpoint or revert`n"
            Write-Modifications -Indent $openedDelta
            return
        }

        if ($active -ne $DEFAULT_FEATURE) {
            $lastFeatureChange = Get-PitFeatureChanges $active | Select-Object -Last 1
        }
        else {
            $lastFeatureChange = $null
        }

        if ($null -ne $lastFeatureChange) {
            $previous = Get-FilesInChange $lastFeatureChange
            $changed = @()

            foreach ($file in $previous) {
                $local = Copy-ShelveToTemp $lastFeatureChange $file.path
                $equal = Compare-Files $file.path $local
                if (-not $equal) {
                    $changed += $file
                }
            }

            $changedCount = $changed | Measure-Object | Select-Object -ExpandProperty count

            if ($changedCount -gt 0) {
                Write-Host -ForegroundColor Red "Your workspace has modified files, submit, checkpoint or revert`n"
                Write-Modifications -Indent $changed
                return
            }

            # Workspace is safe, can delete shelved changes now
            $previous | Select-Object -ExpandProperty path | p4 -x- clean
        }

        # If the feature has changes, unshelve the latest
        if ($Name -ne $DEFAULT_FEATURE) {
            $changes = Get-PitFeatureChanges $Name
            $change = $changes | Select-Object -First 1
            if ($change) {
                p4 unshelve -s $change -c $change
                p4 revert -k -c $change //... 
            }
        }

        Set-Content -Path (Get-PitActiveFeatureFile) -Value $Name
        Write-Host "On feature " -NoNewline
        Write-Host -ForegroundColor Blue "$Name`n"
<#
        Write-Warning "Dry run. Following files would be reverted...`n"
        ($opened | Select-Object -ExpandProperty depotFile) | p4 -x- revert -w -n
        ($unopened | Select-Object -ExpandProperty path) | p4 -x- revert -w -n

        $confirm = Read-Host "`nWould you like to proceed? (yes/no)"
        if ($confirm -ieq "yes") {
            Set-Content -Path (Get-PitActiveFeatureFile) -Value $Name
            # Revert opened
            ($opened | Select-Object -ExpandProperty depotFile) | p4 -x- revert -w
            # Revert unopened
            ($unopened | Select-Object -ExpandProperty path) | p4 -x- revert -w
        }
#>            
    }
}

function Get-PitFeature {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, Position=0)]
        [string[]]$Name
    )

    process {
        if (-not (Test-Path $PIT_CONFIG)) { mkdir $PIT_CONFIG | Out-Null }

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
        [int]$Change,
        [Parameter(Mandatory=$false, Position=1)]
        [string]$Feature
    )

    process {
        if (-not (Test-Path $PIT_CONFIG)) { mkdir $PIT_CONFIG | Out-Null }

        if ($Feature -eq $null) { $Feature = Get-PitActiveFeature }

        $file = Join-Path $PIT_CONFIG "$Feature.feat"
        if (-not (Test-Path $file)) { throw "Feature '$Feature' does not exist" }

        $json = Get-Content -Raw $file
        $data = ConvertFrom-Json $json

        $data.changes += $Change

        $json = ConvertTo-Json $data
        Set-Content -Path $file -Value $json
    }
}

function Get-PitFeatureChanges {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Name
    )

    process {
        if (-not (Test-Path $PIT_CONFIG)) { mkdir $PIT_CONFIG | Out-Null }
        $file = Join-Path $PIT_CONFIG "$Name.feat"
        if (-not (Test-Path $file)) { throw "Feature '$Name' does not exist" }

        $json = Get-Content -Raw $file
        $data = ConvertFrom-Json $json

        Write-Output $data.changes
    }
}

function Set-PitFeatureReview {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Name,
        [Parameter(Mandatory=$true, Position=1)]
        [int]$Review
    )

    process {
        if (-not (Test-Path $PIT_CONFIG)) { mkdir $PIT_CONFIG | Out-Null }
        $file = Join-Path $PIT_CONFIG "$Name.feat"
        if (-not (Test-Path $file)) { throw "Feature '$Name' does not exist" }

        $json = Get-Content -Raw $file
        $data = ConvertFrom-Json $json
        $data.review = $Review
        Set-Content -Path $file -Value $data
    }
}

function Get-PitFeatureReview {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Name
    )

    process {
        if (-not (Test-Path $PIT_CONFIG)) { mkdir $PIT_CONFIG | Out-Null }
        $file = Join-Path $PIT_CONFIG "$Name.feat"
        if (-not (Test-Path $file)) { throw "Feature '$Name' does not exist" }

        $json = Get-Content -Raw $file
        $data = ConvertFrom-Json $json

        Write-Output $data.review
    }
}

function Remove-PitFeature {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Name
    )

    process {
        if (-not (Test-Path $PIT_CONFIG)) { mkdir $PIT_CONFIG | Out-Null }
        $file = Join-Path $PIT_CONFIG "$Name.feat"

        if (-not (Test-Path $file)) { throw "Feature '$Name' does not exist" }

        $changes = Get-PitFeatureChanges -Name $Name
        Write-Host "This command will delete the following changelists:", $changes

        $confirm = Read-Host "`nWould you like to proceed? (yes/no)"
        if ($confirm -ieq "yes") {
            # Todo: check for open files, submit state 
            $changes | Remove-Shelf
            Remove-Item $file
        }
    }
}

function Copy-ShelveToTemp {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [int]$Change,
        [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)]
        [string[]]$File
    )

    begin {
        $tmp = Join-Path $env:temp pit
        if (-not (Test-Path $tmp)) { mkdir $tmp | Out-Null }

        # todo: deal with the possiblity that there are multiple files of the same name,
        # but in different directories, within the same changelist
        $diffTemp = Join-Path $tmp $Change
        if (-not (Test-Path $diffTemp)) { mkdir $diffTemp | Out-Null }
    }

    process {
        foreach ($f in $File) {
            $leaf = Split-Path $f -leaf
            $local = Join-Path $diffTemp $leaf
            p4 print -o $local "$f@=$Change" | Out-Null
            Write-Output $local
        }
    }

    end {
        # Remove-Item -Force -Recurse $diffTemp | Out-Null
    }
}

function Remove-Shelf {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [int]$Change
    )

    process {
        p4 shelve -d -c $Change | Out-Null
        p4 change -d $Change | Out-Null
        Write-Host "Shelf $Change deleted."
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

function Find-OpenFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, Position=0)]
        [string]$Path
    )

    $state = @{name="state"; expression={"op"}}
    $outPath = @{name="path"; expression={$_.clientFile}}

    Invoke-Perforce opened $Path | `
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
                $files += Invoke-Perforce files "//...@=$Change" | Where-Object data -eq $null | `
                    Select-Object action, depotFile, @{name='state'; expression={"sh"}}
            }
        }

        # find all the local paths for the depot paths
        $locations = $files | Select-Object -ExpandProperty depotFile | p4 -ztag -Mj -x - where | ConvertFrom-Json
        $count = $files | Measure-Object | Select-Object -ExpandProperty count

        # Zip the two lists together
        for ($i = 0; $i -lt $count; $i++) { 
            $file = $files[$i]
            $location = $locations[$i]
            $depotFile = $null -ne $location.depotFile ? $location.depotFile : $file.depotFile

            $output = [pscustomobject]@{ 
                action = $file.action; 
                state = $file.state; 
                path = $location.path; 
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
        }
        else {
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

function Compare-WorkspaceToPrevious {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [pscustomobject[]]$File
    )

    begin {
        $feature = Get-PitActiveFeature
        if ($feature -ne $DEFAULT_FEATURE) {
            $lastFeatureChange = Get-PitFeatureChanges $feature | Select-Object -Last 1
            if ($null -ne $lastFeatureChange) {
                $previous = Get-FilesInChange $lastFeatureChange
            }
        }

        $tmp = Join-Path $env:temp pit
        if (-not (Test-Path $tmp)) { mkdir $tmp | Out-Null }

        $diffTemp = Join-Path $tmp "have.$(Get-Random -Maximum 10000)"
        mkdir $diffTemp | Out-Null
    }

    process {
        foreach ($f in $File) {
            $inShelve = $null -ne ($previous | Where-Object path -eq $f.path)

            if ($inShelve) { 
                $leaf = Split-Path $f.path -leaf
                $local = Join-Path $diffTemp $leaf
                p4 print -o $local "$($f.path)@=$lastFeatureChange" | Out-Null

                $equal = Compare-Files $f.path $local
                if (-not $equal) {
                    git diff --no-index $local $f.path
                }
            }
            else { # compare against the have revision
                # todo: deal with the possiblity that there are multiple files of the same name,
                # but in different directories, within the same changelist

                if ($f.action -eq "add") {
                    $leaf = Split-Path $f.path -leaf
                    $local = Join-Path $diffTemp $leaf
                    New-Item -Type File -Path $local -Force | Out-Null

                    git diff --no-index $local $f.path
                }
                elseif ($f.action -eq "delete") {
                    $leaf = Split-Path $f.path -leaf
                    $local = Join-Path $diffTemp "$leaf#empty"
                    $depot = Join-Path $diffTemp "$leaf#have"
                    New-Item -Type File -Path $local -Force | Out-Null
                    p4 print -o $depot "$($f.path)#have" | Out-Null

                    git diff --no-index $depot $local 
                }
                elseif ($f.action -eq "edit") {
                    $leaf = Split-Path $f.path -leaf
                    $depot = Join-Path $diffTemp $leaf
                    p4 print -o $depot "$($f.path)#have" | Out-Null
                    git diff --no-index $depot $f.path
                }
            }
        }
    }

    end {
        Remove-Item -Force -Recurse $diffTemp | Out-Null
    }
}

function Find-DeltaToShelve {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Change
    )

    process {
        $unopened = Find-UnopenFiles ...
        $previous = Get-FilesInChange $Change

        foreach ($file in $unopened) {
            $exists = $null -ne ($previous | Where-Object path -eq $file.path)
            if (-not $exists) { 
                Write-Output $file
            }
            else {
                $local = Copy-ShelveToTemp $lastFeatureChange $file.path
                $equal = Compare-Files $file.path $local
                if (-not $equal) {
                    Write-Output $file
                }
            }
        }
    }
}

function Select-DiffersFromDepot {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [pscustomobject[]]$File
    )

    process {
        foreach ($file in $File) {
            if ($file.action -eq "add" -or $file.action -eq "delete") {
                Write-Output $file
            }
            elseif ($file.action -eq "edit") {
                $tmp = Join-Path $env:temp pit
                if (-not (Test-Path $tmp)) { mkdir $tmp | Out-Null }

                # todo: deal with the possiblity that there are multiple files of the same name,
                # but in different directories, within the same changelist
                $diffTemp = Join-Path $tmp "edit"
                if (-not (Test-Path $diffTemp)) { mkdir $diffTemp | Out-Null }

                $leaf = Split-Path $file.path -leaf
                $depot = Join-Path $diffTemp $leaf
                p4 print -o $depot "$($file.path)#have" | Out-Null

                $equal = Compare-Files $depot $file.path
                if (-not $equal) {
                    Write-Output $file
                }
            }
        }
    }
}

function Add-PitCheckpoint {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Message,
        [Parameter()]
        [switch]$IsAllWrite
    )

    process {
        $feature = Get-PitActiveFeature

        if ($feature -eq $DEFAULT_FEATURE) {
            Write-Host -ForegroundColor Red "Cannot checkpoint against the depot. Create a feature with `"pit feature <name>`""
            return
        }

        if ($IsAllWrite) {
            # Todo: check against previous to see if any have changed, and use that 
            # as the count, not just that there are unopened files
            $unopened = Find-UnopenFiles ...
            $count = $unopened | Measure-Object | Select-Object -ExpandProperty count

            if ($count -eq 0) {
                # Note: git just does a git status and exits
                Write-Host "nothing to submit, workspace clean"
                return
            }
            else {
                Invoke-Perforce reconcile -m ... | Where-Object data -ne $null
            }
        }
        else {
            $opened = Get-FilesInChange default
            $count = $opened | Measure-Object | Select-Object -ExpandProperty count

            if ($count -eq 0) {
                # Note: git just does a git status and exits
                Write-Host "nothing to submit, default changelist empty"
                return
            }
        }

        $cl = New-Changelist -Reopen $Message

        p4 reopen -c $cl ...
        p4 shelve -f -c $cl | Out-Null
        p4 revert -k -c $cl //... | Out-Null

        Add-PitFeatureChange -Feature $feature -Change $cl

        Write-Host "[$feature $cl] $message"
        #Todo: Write-Host " $countChanged file(s) changed..."

        if ($IsAllWrite) {
            p4 revert -k -c $cl //... | Out-Null
        }
        else {
            p4 reopen -c default ...
        }

        Write-Output $cl
    }
}

function Start-SwarmReview {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [int]$Change
    )

    process {
        $info = Invoke-Perforce info
        $user = $info.userName
        $ticket = Get-PerforceTicket | Where-Object user -eq $user | Select-Object -ExpandProperty ticket

        $auth = "{0}:{1}" -f $user, $ticket
        
        $swarm = Invoke-Perforce property -l -n P4.Swarm.URL | Select-Object -ExpandProperty value
        $api = "api/v9/reviews"
        $url = "$swarm$api"

        $result = curl -u $auth -X POST -d "change=$Change" $url | ConvertFrom-Json
        $result | Select-Object -ExpandProperty review | Select-Object -ExpandProperty id
    }
}

<#-- MVP --#>
# Todo: remove pit feature requires "-d" 
# Todo: Remove-feature command (delete all shelves, delete feature, change to "depot" feature)
#   - remove pit feature leaves you on the feature
#   - deletes shelves: done
#   - delete feature: done
# Todo: when setting up a review, check for out of date files and support merging
#   - If not, figure out how to work with updates
# Todo: Review command needs somehow start the review process
#   - Support creating review and adding reviewers?
#   - Use swarm api or changelist comments?
#   - delete feature branch? or is that a manual step? manual step - it's destructive
# Todo: implement nowrite workflow 
#   - pit switch does not work with nowrite workflow
# Todo: Move feature tracking into a json file instead of file-based
#   - This is only mvp because changing file formats would be a breaking change (or require migration)

<#-- Next --#>
# Todo: Move PIT_CONFIG directory to %APPDATA%
# Todo: reset --hard HEAD~n
# Todo: reset --soft HEAD~n
# Todo: checkout HEAD~n
#   - This will make it so you can have symbols in the feature name that aren't invalid for files
# todo: stash, stash list, stash pop?
# Todo: what to do about features that build on other features?
#   - usecase: my feature is in review, I want to start on another feature that depends on the first
#       - in git, branch from the existing branch, rebase on main once feat1 is merged.

# Todo: ??? Swarm updates (these need to go to the same changelist)
# FOR NOW, THIS WORKFLOW ENDS AT THE REVIEW
#   - Need to implement the changelist shuffle :(
#   - see: p4 reshelve
#   - should this always be the flow for the sake of simplicity/consistency?
#   - omg, this is what swarm does under the hood. Could I cheat and use swarm?
#       - swarm.url/api/v9/reviews/?fields=id,changes,stateLabel&change[]=123

# Todo: find-unopened should run on the whole depot, or some well known root. However, I do not
# want to hard-code that root in this file. Might need some kind of pit config file that sets up
# sub-workspaces for large monorepos, where p4 rec //... is really expensive

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
        p4 login -s | Out-Null
        if ($LASTEXITCODE -ne 0) {
            p4 login
        }

        $info = Invoke-Perforce info
        # todo: cache this info somehow
        $client = $info.clientName
        $user = $info.userName
        $clientSpec = Invoke-Perforce client "-o" $client
        $options = $clientSpec | Select-Object -ExpandProperty Options
        $isAllWrite = $options -match "allwrite"

        switch (${__Command__}) {
            "checkpoint" {
                # $isAllWrite = $false
                $message = ${__Remaining__}[0]
                Add-PitCheckpoint -Message $message -IsAllWrite:$isAllWrite | Out-Null
                Write-Host "Start a review with `"pit review...`""
            }
            "clsync" { # Changelist-based syncing. Seems to be really slow (Perforce seems to have a 6 sec overhead for each cl)

                Write-Host "Gathering Changelists to sync..."

                $latest = Invoke-Perforce changes -m1 "@$client" | Select-Object -ExpandProperty change
                [string[]]$changes = Invoke-Perforce changes "-e" $latest -s submitted | `
                    Select-Object -ExpandProperty change -SkipLast 1 | Sort-Object
                $count = $changes.Length

                if ($count -eq 0) {
                    Write-Host "Already up to date."
                }
                else {
                    Write-Host ("Updating {0}..{1}" -f $changes[0], $changes[-1])

                    for ($i = 1; $i -le $count; $i++) { 
                        $change = $changes[$i-1]
                        $percent = ($i/$count) * 100
                        
                        # Write-Host $percent
                        Write-Progress -Activity "Updating" -Status "Syncing $change..." -PercentComplete $percent

                        Invoke-Perforce sync "//...@$change" | Select-Object action, `
                             @{name='path';expression={$_.clientFile}}, @{name='revision';expression={$_.rev}} | `
                             # Out-Host -Paging
                             Out-Null
                    }
                }
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
            "diff" {
                # $isAllWrite = $false

                if ($isAllWrite) {
                    if ($null -eq ${__Remaining__}) {
                        Find-UnopenFiles ... | Compare-WorkspaceToPrevious
                    }
                    else {
                        $files = ${__Remaining__}

                        $changed = @()
                        foreach ($f in $files) {
                            # Todo: handle errors
                            $fullPath = Invoke-Perforce where $f | Select-Object -ExpandProperty path
                            $delta = Find-UnopenFiles $fullPath
                            if ($delta) { $changed += $delta }
                        }

                        $changed | Compare-WorkspaceToPrevious
                    }
                }
                else {
                    if ($null -eq ${__Remaining__}) {
                        Find-OpenFiles | Compare-WorkspaceToPrevious
                    }
                    else {
                        $files = ${__Remaining__}

                        $changed = @()
                        foreach ($f in $files) {
                            # Todo: handle errors
                            $fullPath = Invoke-Perforce where $f | Select-Object -ExpandProperty path
                            $delta = Find-OpenFiles $fullPath
                            if ($delta) { $changed += $delta }
                        }

                        $changed | Compare-WorkspaceToPrevious
                    }
                }
            }
            "feat" {
                Write-Host ${__Remaining__}[0]
                if (@("-d", "--delete").Contains(${__Remaining__}[0])) {
                    Remove-PitFeature ${__Remaining__}[1]
                }
                else {
                    Add-PitFeature ${__Remaining__}[0]
                }
            }
            "filesync" { # File-based syncing (might be faster in some instances, needs more testing)

                Write-Host "Gathering Changelists to sync..."
                $latest = Invoke-Perforce changes -m1 "@$client" | Select-Object -ExpandProperty change
                $changes = Invoke-Perforce changes "-e" $latest -s submitted | `
                    Select-Object -ExpandProperty change -SkipLast 1 | Sort-Object
                $count = $changes | Measure-Object | Select-Object -ExpandProperty count

                if ($count -eq 0) {
                    Write-Host "Already up to date."
                }
                else {
                    Write-Host ("Updating {0}..{1}" -f $changes[0], $changes[-1])

                    for ($i = 1; $i -le $count; $i++) { 
                        $change = $changes[$i-1]
                        $percent = ($i/$count) * 100
                        
                        # Write-Host $percent
                        Write-Progress -Activity "Updating" -Status "Syncing $change..." -PercentComplete $percent

                        $files = Get-FilesInChange $change -Status "submitted"
                        $fileCount = $files | Measure-Object | Select-Object -ExpandProperty count

                        Write-Host "Syncing $fileCount files..."

                        $files | ForEach-Object { "{0}@{1}" -f $_.depotFile, $change } | p4 -ztag -Mj -x- sync | `
                            ConvertFrom-Json | Out-Host -Paging
                    }
                }
            }
            "help" {
                p4 help ${__Remaining__}
            }
            "log" {
                $pageSize = $Host.UI.RawUI.WindowSize.Height - 5
                $more = "-- MORE --"
                $limit = "" 

                $feature = Get-PitActiveFeature
                if ($feature -ne $DEFAULT_FEATURE) {
                    $shelved = Get-PitFeatureChanges $feature
                    $countShelved = $shelved | Measure-Object | Select-Object -ExpandProperty count
                }
                $currentPageSize = $pageSize - $countShelved

                $date = @{name='date';expression={ConvertFrom-UnixTime $_.time}}

                $changes = @()
                foreach ($change in $shelved) {
                    $changes += Invoke-Perforce describe $change | Select-Object change, user, $date, desc
                }

                # Todo: figure out why there is a space in the array

                while ($true) {
                    $changes += Invoke-Perforce changes -L -t -s submitted -m $currentPageSize "//...$limit" ${__Remaining__} `
                        | Select-Object change, user, $date, desc
                    
                    $changes | Out-Host
                    Write-Host -NoNewline "$more"
                    $in = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
                    # q or escape to quit
                    if ($in.Character -eq "q" -or $in.VirtualKeyCode -eq 27) {
                        break
                    }
                    elseif ($in.VirtualKeyCode -eq 32) { # space to page
                        Write-Host "" # just some feedback that the keypress was received
                        $last = $changes | Select-Object -Last 1 -ExpandProperty change
                        $limit = "@$($last - 1)"
                    }

                    $currentPageSize = $pageSize
                    $changes = @()
                }
            }
            "pending" {
                Invoke-Perforce changes -L -u $user -s pending -c $client ${__Remaining__} | Select-Object change, desc
            }
            "new" {
                $cl = New-Changelist ${__Remaining__}[0]
                $env:PIT_CHANGE = $cl
                Write-Output $cl
            }
            "rerev" { # does this need a better name?
                if ($feature -eq $DEFAULT_FEATURE) {
                    Write-Host -ForegroundColor Red "Cannot review against the depot. Create a feature with `"pit feature <name>`""
                    return
                }

                # Todo: validate we're on a valid feature
                if ($isAllWrite) {
                    # Todo: check against previous to see if any have changed, and use that 
                    # as the count, not just that there are unopened files
                    $unopened = Find-UnopenFiles ...
                    $count = $unopened | Measure-Object | Select-Object -ExpandProperty count

                    if ($count -eq 0) {
                        # Note: git just does a git status and exits
                        Write-Host "nothing to shelve, workspace clean"
                        return
                    }
                    else {
                        # Invoke-Perforce reconcile -m ... | Where-Object data -eq $null
                        Invoke-Perforce reconcile -m ... | Out-Null
                    }
                }
                else {
                    $opened = Get-FilesInChange default
                    $count = $opened | Measure-Object | Select-Object -ExpandProperty count

                    if ($count -eq 0) {
                        # Note: git just does a git status and exits
                        Write-Host "nothing to submit, default changelist empty"
                        return
                    }
                }

                $feature = Get-PitActiveFeature
                $cl = Get-PitFeatureReview

                if ($null -eq $cl) {
                    Write-Host -ForegroundColor Red "This feature does not have a review. Creat one with `"pit review`""
                }
                
                p4 reopen -c $cl ...
                p4 shelve -f -c $cl | Out-Null

                Write-Host "[$feature $cl] review updated"
                #Todo: Write-Host " $countChanged file(s) changed..."

                if ($isAllWrite) {
                    p4 revert -k -c $cl //... | Out-Null
                }
                else {
                    p4 reopen -c default ... | Out-Null
                }
            }
            "restore" {
                # Todo: work with multiple/all files
                $file = ${__Remaining__}
                $local = Invoke-Perforce where $file | Select-Object -ExpandProperty path
                Invoke-Perforce clean -m $file | Where-Object data -eq $null | Out-Null
            }
            "review" {
                $feature = Get-PitActiveFeature
                if ($feature -eq $DEFAULT_FEATURE) {
                    Write-Host -ForegroundColor Red "Cannot create review against the depot. Create a feature with `"pit feature <name>`""
                    return
                }

                # Todo: ensure we have work to submit
                #   - ensure there are submits prior to review? or can we just review?
                #       - just review. I found with simple changes, don't need more than the review shelve
                $message = ${__Remaining__}[0]
                $cl = Add-PitCheckpoint -Message $message -IsAllWrite:$isAllWrite
                Set-PitFeatureReview -Name $feature -Review $cl
                
                $swarm = Invoke-Perforce property -l -n P4.Swarm.URL | Select-Object -ExpandProperty value
                Write-Host "Starting the review: $swarm$cl"
                Start-Process "$swarm$cl"
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
                $changes = Invoke-Perforce changes "-e" $latest -s submitted | `
                    Select-Object -ExpandProperty change -SkipLast 1
                $count = $changes | Measure-Object | Select-Object -ExpandProperty count

                if ($count -gt 1) {
                    Write-Warning "Your workspace is $count submits behind the depot."
                }
                elseif ($count -gt 0) {
                    Write-Warning "Your workspace is $count submit behind the depot."
                }
            }
            "status" {
                $feature = Get-PitActiveFeature
                Write-Host "On feature " -NoNewline
                Write-Host -ForegroundColor Blue "$feature`n"

                if ($isAllWrite) {
                    $opened = Find-OpenFiles
                    $openCount = $opened | Measure-Object | Select-Object -ExpandProperty count

                    if ($openCount -gt 0) {
                        Write-Warning "Your workspace has opened files:`n"
                        Write-Modifications -Indent $opened
                    }

                    if ($feature -eq $DEFAULT_FEATURE) {
                        $unopened = Find-UnopenFiles "..." 
                        $countUnopened = $unopened | Measure-Object | Select-Object -ExpandProperty count

                        if ($countUnopened -gt 0) {
                            Write-Host "Changes to submit, checkpoint or revert:"
                            Write-Host "  (use `"pit revert <file>...`" to discard changes in workspace)"
                            Write-Modifications -Indent -Files $unopened
                        }
                        else {
                            Write-Host "nothing to submit, workspace clean"
                        }
                    }
                    else {
                        $lastFeatureChange = Get-PitFeatureChanges $feature | Select-Object -Last 1
                        if ($null -ne $lastFeatureChange) {
                            $changes = Find-DeltaToShelve $lastFeatureChange
                            $countChanged = $changes | Measure-Object | Select-Object -ExpandProperty count

                            if ($countChanged -gt 0) {
                                Write-Host "Changes to submit, checkpoint or revert:"
                                Write-Host "  (use `"pit revert <file>...`" to discard changes in workspace)"
                                Write-Modifications -Indent -Files $changes
                            }
                            else {
                                Write-Host "nothing to submit, workspace clean"
                            }
                        }
                        else {
                            $unopened = Find-UnopenFiles "..." 
                            $countUnopened = $unopened | Measure-Object | Select-Object -ExpandProperty count

                            if ($countUnopened -gt 0) {
                                Write-Host "Changes to submit, checkpoint or revert:"
                                Write-Host "  (use `"pit revert <file>...`" to discard changes in workspace)"
                                Write-Modifications -Indent -Files $unopened
                            }
                            else {
                                Write-Host "nothing to submit, workspace clean"
                            }
                        }
                    }
                }
                else {
                    $opened = Get-FilesInChange default
                    $countOpened = $opened | Measure-Object | Select-Object -ExpandProperty count
                    if ($countOpened -gt 0) {
                        Write-Host "Changes to submit, checkpoint or revert:"
                        Write-Host "  (use `"pit revert <file>...`" to discard changes in workspace)"
                        Write-Modifications -Indent -Files $opened
                    }
                    else {
                        Write-Host "nothing to submit, workspace clean"
                    }
                }

            }
            "submit" {
                if ($feature -eq $DEFAULT_FEATURE) {
                    Write-Host -ForegroundColor Red "Cannot submit against the depot. Create a feature with `"pit feature <name>`""
                    return
                }

                # Todo: ensure we are on a valid feature and we have work to submit
                #   - ensure there is a review prior to submit? or can we just submit?
                
                $feature = Get-PitActiveFeature
                $cl = Get-PitFeatureReview -Name $feature

                if ($null -eq $cl) {
                    Write-Host -ForegroundColor Red "This feature does not have a review. Creat one with `"pit review`""
                }

                # Note: if we just want to submit the shelve:
                #p4 submit -e $cl

                p4 unshelve -s $cl -c $cl | Out-Null
                p4 shelve -d -c $cl | Out-Null
                p4 submit -c $cl

                # NOTE: At this point the `Get-PitFeatureReview` cl is gone. It will have been re-numbered. 
                # Todo: Update the data with the submitted cl number?
            }
            "switch" {
                Set-PitActiveFeature ${__Remaining__}
            }
            "unstage" {
                p4 revert -k -c default ${__Remaining__} | Out-Null
            }
            "update" {
                Write-Host "Gathering files to sync..."
                $files = Invoke-Perforce sync -n | Where-Object data -eq $null
                $count = $files | Measure-Object | Select-Object -ExpandProperty count

                if ($count -eq 0) {
                    Write-Host "Already up to date."
                }
                else {
                    Write-Host "Syncing $count files..."

                    for ($i = 1; $i -le $count; $i++) { 
                        $file = $files[$i-1]
                        $percent = ($i/$count) * 100
                        
                        Write-Progress -Activity "Updating" -Status "Syncing ($i/$count) files..." -PercentComplete $percent

                        # WTF Perforce? What the actual...
                        $rev = ($file.action -eq "deleted") ? $file.rev + 1 : $file.rev

                        $f = "{0}#{1}" -f $file.depotFile, $rev
                        p4 sync $f | Out-Null
                    }

                    $add = $files | Where-Object action -eq "added" | Measure-Object | Select-Object -ExpandProperty count
                    $delete = $files | Where-Object action -eq "deleted" | Measure-Object | Select-Object -ExpandProperty count
                    $edit = $files | Where-Object action -eq "updated" | Measure-Object | Select-Object -ExpandProperty count
                    Write-Host "$edit edits, $add adds, and $delete deletes"
                }
            }
            default {
                Invoke-Perforce ${__Command__} ${__Remaining__}
            }
        }
    }
}

