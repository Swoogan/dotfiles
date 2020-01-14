. .\p5.ps1
. .\p6.ps1

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
