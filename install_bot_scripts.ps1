$ErrorActionPreference = "Stop"

<#
Run from the repository root:

powershell.exe -ExecutionPolicy Bypass -File ".\install_bot_scripts.ps1"

Copies every .gsc file directly inside:

    .\gsc\bots\

into:

    %LOCALAPPDATA%\Plutonium\storage\iw5\z_svr_bots.iwd
    └── maps\mp\bots\

Close WinRAR and Plutonium before running.
#>

$repoRoot = $PSScriptRoot
$sourceBotsFolder = Join-Path $repoRoot "gsc\bots"

$iw5Folder = Join-Path $env:LOCALAPPDATA "Plutonium\storage\iw5"
$iwdPath = Join-Path $iw5Folder "z_svr_bots.iwd"
$backupPath = Join-Path $iw5Folder "z_svr_bots.backup.iwd"

$winRarCandidates = @(
    "C:\Program Files\WinRAR\WinRAR.exe",
    "C:\Program Files (x86)\WinRAR\WinRAR.exe"
)

$winRar = $winRarCandidates |
    Where-Object { Test-Path -LiteralPath $_ } |
    Select-Object -First 1

if (-not $winRar) {
    throw "Could not find WinRAR.exe."
}

if (-not (Test-Path -LiteralPath $sourceBotsFolder)) {
    throw "Could not find source folder: $sourceBotsFolder"
}

if (-not (Test-Path -LiteralPath $iwdPath)) {
    throw "Could not find z_svr_bots.iwd at: $iwdPath"
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

if (-not (Test-Path -LiteralPath $backupPath)) {
    Copy-Item -LiteralPath $iwdPath -Destination $backupPath
    Write-Host "Created backup:" -ForegroundColor DarkGray
    Write-Host "  $backupPath" -ForegroundColor DarkGray
    Write-Host ""
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

Write-Host "Installing Bot Warfare scripts:" -ForegroundColor Cyan

foreach ($file in $botFiles) {
    $archivePath = "maps\mp\bots\$($file.Name)"

    Write-Host "  $archivePath"

    # Remove the existing archive entry, if present.
    $deleteProcess = Start-Process `
        -FilePath $winRar `
        -ArgumentList @(
            "d",
            "`"$iwdPath`"",
            "`"$archivePath`""
        ) `
        -Wait `
        -PassThru `
        -WindowStyle Hidden

    # WinRAR exit code 10 means no matching file existed, which is harmless.
    if ($deleteProcess.ExitCode -ne 0 -and $deleteProcess.ExitCode -ne 10) {
        throw "WinRAR failed while deleting $archivePath (exit code $($deleteProcess.ExitCode))."
    }

    # -ep strips the local source path.
    # -ap explicitly sets the destination folder inside the archive.
    Invoke-WinRar -Arguments @(
        "a",
        "-ep",
        "-o+",
        "-apmaps\mp\bots",
        "`"$iwdPath`"",
        "`"$($file.FullName)`""
    )
}

Write-Host ""
Write-Host "Successfully updated:" -ForegroundColor Green
Write-Host "  $iwdPath" -ForegroundColor Green
Write-Host ""
Write-Host "Installed $($botFiles.Count) bot script(s) into maps\mp\bots\." -ForegroundColor Green
Write-Host "Restart Plutonium or load a new map before testing."
