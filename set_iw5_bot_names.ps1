[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [Alias("FileName")]
    [string] $Path,

    [string] $ServerRoot = "C:\gameserver\IW5",
    [switch] $ClientOnly,
    [switch] $ServerOnly
)

$ErrorActionPreference = "Stop"

<#
Installs a caller-supplied bot-name list as bots.txt at the root of each
selected z_svr_bots.iwd archive. The random-name generator remains separate
and can replace this list later.

Examples:
    .\set_iw5_bot_names.ps1 ".\my_bot_names.txt"
    .\set_iw5_bot_names.ps1 ".\my_bot_names.txt" -ClientOnly
    .\set_iw5_bot_names.ps1 ".\my_bot_names.txt" -ServerOnly -ServerRoot "D:\servers\IW5"

Close WinRAR and Plutonium before running.
#>

$minimumBotNameLength = 3
$maximumBotNameLength = 16
$repoRoot = $PSScriptRoot

. (Join-Path $repoRoot "iw5_targets.ps1")

$clientRoot = Join-Path $env:LOCALAPPDATA "Plutonium\storage\iw5"
$clientIwdPath = Join-Path $clientRoot "z_svr_bots.iwd"
$winRar = Get-WinRarPath

if (Get-Process -Name "WinRAR" -ErrorAction SilentlyContinue) {
    throw "WinRAR is currently open. Close it completely and run the script again."
}

$sourcePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)

if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "Could not find custom bot-name file: $sourcePath"
}

$names = [System.Collections.Generic.List[string]]::new()
$uniqueNames = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase
)

foreach ($sourceLine in [System.IO.File]::ReadAllLines($sourcePath)) {
    $name = $sourceLine.Trim()

    if ([string]::IsNullOrWhiteSpace($name)) {
        continue
    }

    if (
        $name.Length -lt $minimumBotNameLength -or
        $name.Length -gt $maximumBotNameLength
    ) {
        throw "Bot name must contain 3-16 characters: $name"
    }

    if ($name -match '[^\x20-\x7E]') {
        throw "Bot name contains non-ASCII characters: $name"
    }

    if (-not $uniqueNames.Add($name)) {
        throw "Duplicate bot name: $name"
    }

    [void] $names.Add($name)
}

if ($names.Count -eq 0) {
    throw "The custom bot-name file does not contain any valid names: $sourcePath"
}

$targets = @(Get-Iw5Targets `
    -ServerRoot $ServerRoot `
    -ClientOnly:$ClientOnly `
    -ServerOnly:$ServerOnly)

$stagingRoot = Join-Path `
    ([System.IO.Path]::GetTempPath()) `
    ("iw5-custom-bot-names-" + [guid]::NewGuid().ToString("N"))
$stagedBotsFile = Join-Path $stagingRoot "bots.txt"

Add-Type -AssemblyName System.IO.Compression.FileSystem

try {
    New-Item -ItemType Directory -Force -Path $stagingRoot | Out-Null

    [System.IO.File]::WriteAllLines(
        $stagedBotsFile,
        [string[]] $names,
        [System.Text.Encoding]::ASCII
    )

    Write-Host "Custom bot names ($($names.Count)):" -ForegroundColor Cyan
    $names | ForEach-Object { Write-Host "  $_" }

    foreach ($target in $targets) {
        if (-not (Test-Path -LiteralPath $target.Root -PathType Container)) {
            throw "$($target.Name) root does not exist: $($target.Root)"
        }

        $iwdPath = Join-Path $target.Root "z_svr_bots.iwd"

        if (-not (Test-Path -LiteralPath $iwdPath -PathType Leaf)) {
            if ($target.Root -eq $clientRoot) {
                throw "Could not find z_svr_bots.iwd at: $iwdPath"
            }

            if (-not (Test-Path -LiteralPath $clientIwdPath -PathType Leaf)) {
                throw "Cannot seed the server archive because the client archive is missing: $clientIwdPath"
            }

            Copy-Item -LiteralPath $clientIwdPath -Destination $iwdPath
            Write-Host "Seeded Bot Warfare archive: $iwdPath" -ForegroundColor DarkGray
        }

        & $winRar d -ibck $iwdPath "bots.txt" | Out-Null
        & $winRar a -ibck -ep $iwdPath $stagedBotsFile | Out-Null

        if ($LASTEXITCODE -ne 0) {
            throw "WinRAR failed to update: $iwdPath"
        }

        $archive = [System.IO.Compression.ZipFile]::OpenRead($iwdPath)

        try {
            $entry = $archive.GetEntry("bots.txt")

            if ($null -eq $entry) {
                throw "Archive validation failed for $iwdPath. Missing root entry: bots.txt"
            }

            $reader = [System.IO.StreamReader]::new(
                $entry.Open(),
                [System.Text.Encoding]::ASCII
            )

            try {
                $installedNames = @(
                    while (-not $reader.EndOfStream) {
                        $reader.ReadLine()
                    }
                )
            }
            finally {
                $reader.Dispose()
            }
        }
        finally {
            $archive.Dispose()
        }

        if (
            $installedNames.Count -ne $names.Count -or
            [string]::Join("`n", $installedNames) -cne
                [string]::Join("`n", [string[]] $names)
        ) {
            throw "Archive validation failed for $iwdPath. Installed bots.txt does not match $sourcePath"
        }

        Write-Host "Updated and verified: $iwdPath" -ForegroundColor Green
    }
}
finally {
    if (Test-Path -LiteralPath $stagingRoot) {
        Remove-Item -LiteralPath $stagingRoot -Recurse -Force
    }
}

Write-Host ""
Write-Host "Installed $($names.Count) custom bot name(s) to $($targets.Count) target(s)." -ForegroundColor Green
Write-Host "Restart Plutonium or load a new map before testing."
