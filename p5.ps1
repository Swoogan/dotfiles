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

        $config = "$(Find-Config)/config"
        if (Test-Path $config) {
            $info = Get-Content -Raw $config
            Invoke-Expression $info
        }

        $noFiles = "*o file(s) to reconcile.*"

        <#
        TODO: just delete the client for a already deleted branch
        TODO: just create the client for a already created branch
        #>
                
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
                p4 changes -L -t -s submitted -u $Env:Username ${__Remaining__} $branchesRoot/$env:P5BRANCH/... | more
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
                $cl = New-Changelist ${__Remaining__}[0]  
                $env:P5CHANGE = $cl
                #[System.Environment]::SetEnvironmentVariable('P4CHANGE', $cl, [System.EnvironmentVariableTarget]::User)
                Write-Output $cl
                Reset-Colors
            }
            "reopen" {
                    p4 -F %depotFile% opened -c default | p4 -x - reopen -c ${__Remaining__}[0]
            }
            "ud" { # Update description
                p4 --field Description=${__Remaining__}[1] change -o ${__Remaining__}[0] | p4 change -i
            }
            "status" {
                p4 reconcile -n
            }
            "rec" {
                p4 reconcile -c $env:P5CHANGE
            }
            "add" {
                if (Test-Path env:P5CHANGE)  {
                    p4 reconcile -c $env:P5CHANGE
                } else {
                    Write-Warning "No changelist present"
                }
            }
            "changes" {
                $cls = p4 -z tag -F %change% changes -u $Env:Username -s pending -c $client 
                foreach ($cl in $cls) {
                    Write-Output "`n Changelist $cl`n"
                    $files = p4 -z tag -F "%action%:`t%localFile%" status
                    $files | % { Write-Output "`t$_" }
                }
                Write-Output ""
            }
            "branches" {
                p4 -ztag -F %branch% branches -u $env:username
            }
            "branch" {
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

                p4 sync $branchesRoot/$branchName/...
                cd $branchesRoot/$branchName

                # store jira
            }
            "db" {  # Delete branch
                $branchName = ${__Remaining__}[0]

                p4 set P4CLIENT="$wsNameRoot$branchName"

                echo "$branchesRoot/$branchName/..."
                $cl = New-Changelist "Removing branch $branchName"
                p4 delete -c $cl "$branchesRoot/$branchName/..."
                p4 submit -c $cl

                p4 branch -d "$branchNameRoot$branchName"
                p4 client -d "$wsNameRoot$branchName"

                Remove-Item -Recurse -Force $branchesRoot/$branchName
            }
            "checkout" {
                $switchBranch = {
                    $branchName = ${__Remaining__}[0]
                    p4 set P4CLIENT="$wsNameRoot$branchName"
                    $env:P5BRANCH=$branchName

                    if (-not (Test-Path "$branchesRoot/$branchName")) {
                        p4 sync "$branchesRoot/$branchName"
                    }

                    cd "$branchesRoot/$branchName"
                    Write-Host "Switched to branch $wsNameRoot$branchName"
                }

                if (Test-path env:\P5BRANCH) {
                    $rc = p4 reconcile -n "$branchesRoot/$($env:P5BRANCH)/..." 2>&1

                    if ($rc.Exception.Message -like $noFiles) { 
                        Invoke-Command -ScriptBlock $switchBranch
                    } else {
                        Write-Warning "You have local changes. Submit or stash."
                    }
                } else {
                    Invoke-Command -ScriptBlock $switchBranch
                }
            }
            "which" {
                Write-Output $client
            }
            default {
                p4 ${__Command__} ${__Remaining__}
            }
        }
    }

    # Change file type: `p4 reopen -c $cl -t text`
}

