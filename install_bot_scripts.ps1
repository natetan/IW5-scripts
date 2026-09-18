[CmdletBinding()]
param(
    [string] $ServerRoot = "C:\gameserver\IW5",
    [switch] $ClientOnly,
    [switch] $ServerOnly
)

$ErrorActionPreference = "Stop"

<#
Updates maps\mp\bots inside z_svr_bots.iwd in both the local Plutonium
storage folder and the dedicated server by default.

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
. (Join-Path $repoRoot "iw5_targets.ps1")

$clientRoot = Join-Path $env:LOCALAPPDATA "Plutonium\storage\iw5"
$clientIwdPath = Join-Path $clientRoot "z_svr_bots.iwd"
$winRar = Get-WinRarPath

if (-not (Test-Path -LiteralPath $sourceBotsFolder -PathType Container)) {
    throw "Could not find source folder: $sourceBotsFolder"
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

function Invoke-WinRar {
    param(
        [Parameter(Mandatory)]
        [string[]] $Arguments
    )

    $process = Start-Process `
        -FilePath $winRar `
        -ArgumentList $Arguments `
        -Wait `
        -PassThru `
        -WindowStyle Hidden

    if ($process.ExitCode -ne 0) {
        throw "WinRAR exited with code $($process.ExitCode)."
    }
}

$targets = @(Get-Iw5Targets `
    -ServerRoot $ServerRoot `
    -ClientOnly:$ClientOnly `
    -ServerOnly:$ServerOnly)

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

    foreach ($file in $botFiles) {
        $archivePath = "maps\mp\bots\$($file.Name)"
        Write-Host "  $archivePath"

        $deleteProcess = Start-Process `
            -FilePath $winRar `
            -ArgumentList @("d", "`"$iwdPath`"", "`"$archivePath`"") `
            -Wait `
            -PassThru `
            -WindowStyle Hidden

        # WinRAR exit code 10 means no matching file existed, which is harmless.
        if ($deleteProcess.ExitCode -ne 0 -and $deleteProcess.ExitCode -ne 10) {
            throw "WinRAR failed while deleting $archivePath (exit code $($deleteProcess.ExitCode))."
        }

        Invoke-WinRar -Arguments @(
            "a",
            "-ep",
            "-o+",
            "-apmaps\mp\bots",
            "`"$iwdPath`"",
            "`"$($file.FullName)`""
        )
    }

    Write-Host "Updated: $iwdPath" -ForegroundColor Green
}

Write-Host ""
Write-Host "Installed $($botFiles.Count) bot script(s) to $($targets.Count) target(s)." -ForegroundColor Green
Write-Host "Restart Plutonium or load a new map before testing."
