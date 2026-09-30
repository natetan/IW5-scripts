[CmdletBinding()]
param(
    [string] $ServerRoot = "C:\gameserver\IW5",
    [switch] $ClientOnly,
    [switch] $ServerOnly
)

$ErrorActionPreference = "Stop"

<#
Updates maps\mp\bots and the map waypoint scripts under scripts\mp inside
z_svr_bots.iwd in both the local Plutonium storage folder and the dedicated
server by default.

If the dedicated server does not have z_svr_bots.iwd yet, the current client
archive is copied there before it is updated.

Examples:
    .\install_bot_scripts.ps1
    .\install_bot_scripts.ps1 -ClientOnly
    .\install_bot_scripts.ps1 -ServerOnly -ServerRoot "D:\servers\IW5"

Close WinRAR and Plutonium before running.
#>

$repoRoot = $PSScriptRoot
$sourceBotsFolder = Join-Path $repoRoot "gsc\bots"
$sourceWaypointsFolder = Join-Path $repoRoot "waypoints"
. (Join-Path $repoRoot "iw5_targets.ps1")

$clientRoot = Join-Path $env:LOCALAPPDATA "Plutonium\storage\iw5"
$clientIwdPath = Join-Path $clientRoot "z_svr_bots.iwd"
$winRar = Get-WinRarPath

Add-Type -AssemblyName System.IO.Compression.FileSystem

if (-not (Test-Path -LiteralPath $sourceBotsFolder -PathType Container)) {
    throw "Could not find source folder: $sourceBotsFolder"
}

if (-not (Test-Path -LiteralPath $sourceWaypointsFolder -PathType Container)) {
    throw "Could not find source waypoint folder: $sourceWaypointsFolder"
}

if (Get-Process -Name "WinRAR" -ErrorAction SilentlyContinue) {
    throw "WinRAR is currently open. Close it completely and run the script again."
}

$botFiles = @(
    Get-ChildItem -LiteralPath $sourceBotsFolder -File -Filter "*.gsc" |
        Sort-Object Name
)

if ($botFiles.Count -eq 0) {
    throw "No .gsc files were found in: $sourceBotsFolder"
}

$waypointFiles = @(
    Get-ChildItem -LiteralPath $sourceWaypointsFolder -Recurse -File -Filter "*.gsc" |
        Sort-Object FullName
)

if ($waypointFiles.Count -eq 0) {
    throw "No waypoint .gsc files were found in: $sourceWaypointsFolder"
}

function Invoke-WinRar {
    param(
        [Parameter(Mandatory)]
        [string[]] $Arguments,

        [string] $WorkingDirectory
    )

    $startProcessArguments = @{
        FilePath = $winRar
        ArgumentList = $Arguments
        Wait = $true
        PassThru = $true
        WindowStyle = "Hidden"
    }

    if ($WorkingDirectory) {
        $startProcessArguments.WorkingDirectory = $WorkingDirectory
    }

    $process = Start-Process @startProcessArguments

    if ($process.ExitCode -ne 0) {
        throw "WinRAR exited with code $($process.ExitCode)."
    }
}

function Assert-IwdEntries {
    param(
        [Parameter(Mandatory)]
        [string] $IwdPath,

        [Parameter(Mandatory)]
        [string[]] $ExpectedEntries
    )

    $archive = [System.IO.Compression.ZipFile]::OpenRead($IwdPath)

    try {
        $archiveEntries = @{}

        foreach ($entry in $archive.Entries) {
            $normalizedName = $entry.FullName.Replace("\", "/").ToLowerInvariant()
            $archiveEntries[$normalizedName] = $true
        }

        $missingEntries = @(
            foreach ($expectedEntry in $ExpectedEntries) {
                $normalizedExpected = $expectedEntry.Replace("\", "/").ToLowerInvariant()

                if (-not $archiveEntries.ContainsKey($normalizedExpected)) {
                    $expectedEntry
                }
            }
        )

        if ($missingEntries.Count -gt 0) {
            throw "Archive validation failed for $IwdPath. Missing entries:`n  $($missingEntries -join "`n  ")"
        }
    }
    finally {
        $archive.Dispose()
    }

    Write-Host "  Verified $($ExpectedEntries.Count) expected archive entries." -ForegroundColor Green
}

$targets = @(Get-Iw5Targets `
    -ServerRoot $ServerRoot `
    -ClientOnly:$ClientOnly `
    -ServerOnly:$ServerOnly)

$stagingRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("iw5-bot-install-" + [guid]::NewGuid().ToString("N"))
$stagedBotsFolder = Join-Path $stagingRoot "maps\mp\bots"
$stagedWaypointsFolder = Join-Path $stagingRoot "scripts\mp"
$expectedEntries = @(
    foreach ($file in $botFiles) {
        "maps/mp/bots/$($file.Name)"
    }

    foreach ($file in $waypointFiles) {
        "scripts/mp/$($file.Directory.Name)/$($file.Name)"
    }
)

try {
    New-Item -ItemType Directory -Force -Path $stagedBotsFolder, $stagedWaypointsFolder | Out-Null

    foreach ($file in $botFiles) {
        Copy-Item -LiteralPath $file.FullName -Destination $stagedBotsFolder
    }

    foreach ($file in $waypointFiles) {
        $mapFolder = Join-Path $stagedWaypointsFolder $file.Directory.Name
        New-Item -ItemType Directory -Force -Path $mapFolder | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $mapFolder
    }

    foreach ($target in $targets) {
        if (-not (Test-Path -LiteralPath $target.Root -PathType Container)) {
            throw "$($target.Name) root does not exist: $($target.Root)"
        }

        $iwdPath = Join-Path $target.Root "z_svr_bots.iwd"
        $backupPath = Join-Path $target.Root "z_svr_bots.backup.iwd"

        if (-not (Test-Path -LiteralPath $iwdPath -PathType Leaf)) {
            if ($target.Root -eq $clientRoot) {
                throw "Could not find z_svr_bots.iwd at: $iwdPath"
            }

            if (-not (Test-Path -LiteralPath $clientIwdPath -PathType Leaf)) {
                throw "Cannot seed the server archive because the client archive is missing: $clientIwdPath"
            }

            Copy-Item -LiteralPath $clientIwdPath -Destination $iwdPath
            Write-Host "Seeded Bot Warfare archive:" -ForegroundColor DarkGray
            Write-Host "  $iwdPath" -ForegroundColor DarkGray
        }

        if (-not (Test-Path -LiteralPath $backupPath -PathType Leaf)) {
            Copy-Item -LiteralPath $iwdPath -Destination $backupPath
            Write-Host "Created backup:" -ForegroundColor DarkGray
            Write-Host "  $backupPath" -ForegroundColor DarkGray
        }

        Write-Host ""
        Write-Host "Installing Bot Warfare scripts to $($target.Name):" -ForegroundColor Cyan

        Write-Host "  Updating $($botFiles.Count + $waypointFiles.Count) files in one archive operation..."

        Invoke-WinRar `
            -WorkingDirectory $stagingRoot `
            -Arguments @(
                "a",
                "-r",
                "-o+",
                "`"$iwdPath`"",
                "maps",
                "scripts"
            )

        Assert-IwdEntries -IwdPath $iwdPath -ExpectedEntries $expectedEntries

        Write-Host "Updated: $iwdPath" -ForegroundColor Green
    }
}
finally {
    if (Test-Path -LiteralPath $stagingRoot) {
        Remove-Item -LiteralPath $stagingRoot -Recurse -Force
    }
}

Write-Host ""
Write-Host "Installed $($botFiles.Count) bot script(s) and $($waypointFiles.Count) waypoint script(s) to $($targets.Count) target(s)." -ForegroundColor Green
Write-Host "Restart Plutonium or load a new map before testing."
