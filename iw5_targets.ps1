$ErrorActionPreference = "Stop"

function Get-Iw5Targets {
    param(
        [string] $ServerRoot = "C:\gameserver\IW5",
        [switch] $ClientOnly,
        [switch] $ServerOnly
    )

    if ($ClientOnly -and $ServerOnly) {
        throw "ClientOnly and ServerOnly cannot be used together."
    }

    $targets = [System.Collections.Generic.List[object]]::new()

    if (-not $ServerOnly) {
        [void] $targets.Add([pscustomobject]@{
            Name = "Plutonium client storage"
            Root = Join-Path $env:LOCALAPPDATA "Plutonium\storage\iw5"
        })
    }

    if (-not $ClientOnly) {
        if ([string]::IsNullOrWhiteSpace($ServerRoot)) {
            throw "ServerRoot cannot be empty when deploying to the dedicated server."
        }

        [void] $targets.Add([pscustomobject]@{
            Name = "IW5 dedicated server"
            Root = [System.IO.Path]::GetFullPath($ServerRoot)
        })
    }

    return $targets
}

function Get-WinRarPath {
    $winRar = @(
        "C:\Program Files\WinRAR\WinRAR.exe",
        "C:\Program Files (x86)\WinRAR\WinRAR.exe"
    ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

    if (-not $winRar) {
        throw "Could not find WinRAR.exe."
    }

    return $winRar
}
