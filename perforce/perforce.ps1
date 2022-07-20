#. "$HOME\p5\p5.ps1"
# . "$HOME\p5\p6.ps1"

# function Move-P4File ([string]$Path, [string]$Destination) {
#     p4 edit $Path
#     Get-ChildItem $Path | ForEach-Object { p4 move $_.FullName ("{0}\{1}" -f $Destination, $_.Name)}
# }
#
# function Rename-P4File ([string]$Path, [string]$Destination) {
#     p4 edit $Path
#
#     foreach ($file in $(Get-ChildItem $Path)) {
#         $fn = $file.Name
#         $slash = $fn.IndexOf("\")
#         [int]$dot
#         if ($slash -ne -1) {
#             $dot = $fn.IndexOf(".", $slash)
#         } else {
#             $dot = $fn.IndexOf(".")
#         }
#         $tail = $fn.Substring($dot)
#         p4 move $fn (".\{0}{1}" -f $Destination, $tail)
#     }
# }

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
        $cl = p4 --field "Description=$Message" change -o | 
            p4 change -i | 
            select-string "\b(\d+)" | 
            ForEach-Object {$_.matches[0].value}

        Write-Output $cl
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
            "pending" {
                Invoke-Perforce changes -u $user -s pending -c $client ${__Remaining__} | select change, desc
            }
            "state" {
                Write-Host "`n[default]`n"
                $files = Invoke-Perforce opened -c default

                $result = $files | ForEach-Object {
                    # todo: use p4 -x - where
                    $where = Invoke-Perforce where $_.depotFile
                    Write-Output @{ action = $_.action; path = $where.path }
                }

                foreach ($file in $result) {
                    if ($file.action -eq "add") {
                        Write-Host -ForegroundColor Yellow "`t[add]    $($file.path)"
                    }
                    elseif ($file.action -eq "edit") {
                        Write-Host -ForegroundColor Green "`t[edit]   $($file.path)"
                    }
                    elseif ($file.action -eq "delete") {
                        Write-Host -ForegroundColor Red "`t[delete] $($file.path)"
                    }
                }

                Write-Host ""

                # TODO: might need a way to display whether the files are shelved or not
                $pending = Invoke-Perforce changes -u $user -s pending -c $client ${__Remaining__}
                foreach ($cl in $pending) {

                    Write-Host "[$($cl.change)] $($cl.desc)"
                    $desc = Invoke-Perforce describe $cl.change
                    $shelf = $desc.shelved -ne $null

                    if ($shelf) {
                        $files = Invoke-Perforce files "//...@=$($cl.change)"
                    }
                    else {
                        $files = Invoke-Perforce opened -c $cl.change
                    }

                    foreach ($file in $files) {
                        $where = Invoke-Perforce where $file.depotFile
                        if ($file.action -eq "add") {
                            Write-Host -ForegroundColor Yellow "`t[add]    $($where.path)"
                        }
                        elseif ($file.action -eq "edit") {
                            Write-Host -ForegroundColor Green "`t[edit]   $($where.path)"
                        }
                        elseif ($file.action -eq "delete") {
                            Write-Host -ForegroundColor Red "`t[delete] $($where.path)"
                        }
                    }

                    Write-Host ""
                }

                Write-Host "[unopened]`n"
                $files = Invoke-Perforce reconcile -n ...

                foreach ($file in $files) {
                    if ($file.action -eq "add") {
                        Write-Host -ForegroundColor Yellow "`t[add]    $($file.clientFile)"
                    }
                    elseif ($file.action -eq "edit") {
                        Write-Host -ForegroundColor Green "`t[edit]   $($file.clientFile)"
                    }
                    elseif ($file.action -eq "delete") {
                        Write-Host -ForegroundColor Red "`t[delete] $($file.clientFile)"
                    }
                }

                Write-Host ""
            }
            "new" {
                $cl = New-Changelist ${__Remaining__}[0]
                $env:PIT_CHANGE = $cl
                Write-Output $cl
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
