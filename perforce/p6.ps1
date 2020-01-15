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
        # TODO: re-evaluate if this is needed
        if (-not (Test-Path ~/.p5)) {
            New-Item -Type directory ~/.p5
        }

        $config = "$(Find-Config)/config"
        if (Test-Path $config) {
            $info = Get-Content -Raw $config
            Invoke-Expression $info
        }

        # TODO: Find .p4config
#        $config = "$(Find-Config)/config"
#        if (Test-Path $config) {
#            $info = Get-Content -Raw $config
#            Invoke-Expression $info
#        }

        $noFiles = "*o file(s) to reconcile.*"

        switch (${__Command__}) {
            "status" {
                p4 status
            }
            "add" {
                p4 reconcile ${__Remaining__}
            }
            "cmm" {
                p4 submit -d ${__Remaining__}[0]
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
            default {
                Write-Error "Unknown PeeFive command"
            }
        }
    }

    # Change file type: `p4 reopen -c $cl -t text`
}


