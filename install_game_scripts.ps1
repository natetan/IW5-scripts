[CmdletBinding()]
param(
    [string] $ServerRoot = "C:\gameserver\IW5",
    [switch] $ClientOnly,
    [switch] $ServerOnly
)

$ErrorActionPreference = "Stop"

<#
Installs the repository's loose IW5 files to both the local Plutonium storage
folder and the dedicated server by default.

Examples:
    .\install_game_scripts.ps1
    .\install_game_scripts.ps1 -ClientOnly
    .\install_game_scripts.ps1 -ServerOnly -ServerRoot "D:\servers\IW5"
#>

$repoRoot = $PSScriptRoot
. (Join-Path $repoRoot "iw5_targets.ps1")

$sourceMappings = @(
    [pscustomobject]@{ Source = "gsc"; Destination = "scripts" },
    [pscustomobject]@{ Source = "players"; Destination = "players" },
    [pscustomobject]@{ Source = "admin"; Destination = "admin" },
    [pscustomobject]@{ Source = "maps"; Destination = "maps" }
)

function Merge-NormalConfigIntoServerConfig {
    param(
        [Parameter(Mandatory)]
        [string] $NormalConfigPath,

        [Parameter(Mandatory)]
        [string] $ServerConfigPath
    )

    if (-not (Test-Path -LiteralPath $ServerConfigPath -PathType Leaf)) {
        throw "Dedicated server config does not exist: $ServerConfigPath"
    }

    $startMarker = "// BEGIN MANAGED NORMAL.CFG SETTINGS"
    $endMarker = "// END MANAGED NORMAL.CFG SETTINGS"
    $newline = "`r`n"
    $normalConfig = (Get-Content -LiteralPath $NormalConfigPath -Raw).Trim()
    $serverConfig = Get-Content -LiteralPath $ServerConfigPath -Raw

    $managedBlock = @(
        $startMarker
        "// Generated from the repository's players\normal.cfg."
        "// Re-run install_game_scripts.ps1 after changing normal.cfg."
        $normalConfig
        $endMarker
    ) -join $newline

    $escapedStart = [regex]::Escape($startMarker)
    $escapedEnd = [regex]::Escape($endMarker)
    $managedPattern = "(?s)$escapedStart.*?$escapedEnd"

    if ([regex]::IsMatch($serverConfig, $managedPattern)) {
        $mergedConfig = [regex]::Replace(
            $serverConfig,
            $managedPattern,
            [System.Text.RegularExpressions.MatchEvaluator] { param($match) $managedBlock },
            1
        )
    }
    else {
        $rotationPattern = "(?m)^\s*seta?\s+sv_maprotation\b"
        $rotationMatch = [regex]::Match($serverConfig, $rotationPattern)

        if ($rotationMatch.Success) {
            $mergedConfig = $serverConfig.Insert(
                $rotationMatch.Index,
                "$managedBlock$newline$newline"
            )
        }
        else {
            $mergedConfig = $serverConfig.TrimEnd() +
                "$newline$newline$managedBlock$newline"
        }
    }

    $backupPath = "$ServerConfigPath.pre-custom-scripts.backup"
    if (-not (Test-Path -LiteralPath $backupPath -PathType Leaf)) {
        Copy-Item -LiteralPath $ServerConfigPath -Destination $backupPath
        Write-Host "  backup   -> $backupPath" -ForegroundColor DarkGray
    }

    [System.IO.File]::WriteAllText(
        $ServerConfigPath,
        $mergedConfig,
        [System.Text.Encoding]::ASCII
    )

    Write-Host "  merged   -> $ServerConfigPath" -ForegroundColor Green
}

$targets = @(Get-Iw5Targets `
    -ServerRoot $ServerRoot `
    -ClientOnly:$ClientOnly `
    -ServerOnly:$ServerOnly)

foreach ($target in $targets) {
    if (-not (Test-Path -LiteralPath $target.Root -PathType Container)) {
        throw "$($target.Name) root does not exist: $($target.Root)"
    }

    Write-Host ""
    Write-Host "Installing game files to $($target.Name):" -ForegroundColor Cyan

    foreach ($mapping in $sourceMappings) {
        $source = Join-Path $repoRoot $mapping.Source
        $destination = Join-Path $target.Root $mapping.Destination

        if (-not (Test-Path -LiteralPath $source -PathType Container)) {
            throw "Source folder does not exist: $source"
        }

        New-Item -ItemType Directory -Force -Path $destination | Out-Null
        Copy-Item `
            -Path (Join-Path $source "*") `
            -Destination $destination `
            -Recurse `
            -Force

        Write-Host ("  {0,-8} -> {1}" -f $mapping.Source, $destination)
    }

    if ($target.Name -eq "IW5 dedicated server") {
        Merge-NormalConfigIntoServerConfig `
            -NormalConfigPath (Join-Path $repoRoot "players\normal.cfg") `
            -ServerConfigPath (Join-Path $target.Root "admin\server.cfg")
    }
}

Write-Host ""
Write-Host "Installed game files to $($targets.Count) target(s)." -ForegroundColor Green
