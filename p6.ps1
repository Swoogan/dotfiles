function Invoke-PeeFive {
    [CmdletBinding()]
    param (
        # Command. I use three underscores so that variable shorten won't still switches I'm trying to pass to ${__Remaining__}
        [Parameter(Mandatory=$true, Position=0)]
        [string] ${__Command__}, 
        [Parameter(Mandatory=$false, Position=1, ValueFromRemainingArguments=$true)]
        ${__Remaining__}
    )
        
    process {
        if (-not (Test-Path ~/.p5)) {
            New-Item -Type directory ~/.p5
        }

        $client = $(p4 -Ztag -F %clientName% info)

        $config = "$(Find-Config)/config"
        if (Test-Path $config) {
            $info = Get-Content -Raw $config
            Invoke-Expression $info
        }

        $noFiles = "*o file(s) to reconcile.*"

        switch (${__Command__}) {
            "new" {
                $cl = New-Changelist ${__Remaining__}[0]  
                $env:P6CHANGE = $cl
                #[System.Environment]::SetEnvironmentVariable('P4CHANGE', $cl, [System.EnvironmentVariableTarget]::User)
                Write-Output $cl
                Reset-Colors
            }
            "ud" { # Update description
                p4 --field Description=${__Remaining__}[1] change -o ${__Remaining__}[0] | p4 change -i
            }
            "status" {
                if ($env:P6CHANGE) {
                    p4 describe -c $env:P6CHANGE
                }
                p4 reconcile -n
            }
            "add" {
                if ($env:P6CHANGE)  {
                    p4 reconcile -c $env:P6CHANGE ${__Remaining__}
                } else {
                    Write-Verbose "No changelist present"
                    $cl = New-Changelist "<auto add>"
                    $env:P6CHANGE = $cl
                    p4 reconcile -c $env:P6CHANGE ${__Remaining__}
                }
                Reset-Colors
            }
            "cmm" {
                if (-not $env:P6CHANGE)  {
                    Write-Warning "No changelist present"
                } else {
                    p4 --field Description=${__Remaining__}[1] change -o ${__Remaining__}[0] | p4 change -i
                    p4 submit -c $env:P6CHANGE
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
            "which" {
                Write-Output $client
            }
            default {
                Write-Error "Unknown PeeFive command"
            }
        }
    }

    # Change file type: `p4 reopen -c $cl -t text`
}


