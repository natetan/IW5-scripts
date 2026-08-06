# powershell.exe -ExecutionPolicy Bypass -File ".\install_game_scripts.ps1"

$repoRoot = $PSScriptRoot

$iw5 = Join-Path $env:LOCALAPPDATA "Plutonium\storage\iw5"

$scriptDst = Join-Path $iw5 "scripts"
$playerDst = Join-Path $iw5 "players"
$adminDst = Join-Path $iw5 "admin"

New-Item -ItemType Directory -Force $scriptDst | Out-Null
New-Item -ItemType Directory -Force $playerDst | Out-Null

Copy-Item "$repoRoot\gsc\*" `
          $scriptDst `
          -Recurse `
          -Force

Copy-Item "$repoRoot\players\*" `
          $playerDst `
          -Recurse `
          -Force

Copy-Item "$repoRoot\admin\*" `
          $adminDst `
          -Recurse `
          -Force

Write-Host ""
Write-Host "Installed game scripts." -ForegroundColor Green
Write-Host "Scripts  -> $scriptDst"
Write-Host "Players  -> $playerDst"
Write-Host "Players  -> $adminDst"