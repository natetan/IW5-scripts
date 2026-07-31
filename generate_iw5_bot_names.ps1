$ErrorActionPreference = "Stop"

# Change this path if your Plutonium folder is elsewhere.
$iw5Folder = Join-Path $env:LOCALAPPDATA "Plutonium\storage\iw5"
$iwdPath = Join-Path $iw5Folder "z_svr_bots.iwd"

# WinRAR command-line executable.
# Update this if WinRAR is installed elsewhere.
$winRar = "C:\Program Files\WinRAR\WinRAR.exe"

if (-not (Test-Path $iwdPath)) {
    throw "Could not find z_svr_bots.iwd at: $iwdPath"
}

if (-not (Test-Path $winRar)) {
    throw "Could not find WinRAR at: $winRar"
}

# Short, cleaner names that resemble sweaty/competitive aliases.
$tryhardPrefixes = @(
    "Astra", "Blitz", "Cipher", "Cinder", "Crux", "Cryo", "Dusk",
    "Echo", "Ember", "Fable", "Frost", "Ghost", "Glint", "Havoc", "Hex",
    "Hollow", "Ion", "Kairo", "Karma", "Lucid", "Lumen", "Mako", "Nero",
    "Nexus", "Nova", "Nyx", "Onyx", "Orbit", "Phantom", "Pulse", "Raze",
    "Reign", "Rift", "Rune", "Sever", "Shade", "Solar", "Specter", "Static",
    "Storm", "Strafe", "Stryke", "Syn", "Vanta", "Vex", "Void", "Volt",
    "Wraith", "Zen", "Zero"
)

$tryhardSuffixes = @(
    "a", "al", "an", "ane", "ant", "ar", "ax", "en", "ent", "er",
    "ex", "ic", "ics", "ion", "is", "ix", "ium", "ive", "or", "ous",
    "ox", "um", "us", "yn", "yx"
)

# Early-2010s wannabe-MLG styling. Most bots come from this group.
$mlgPrefixes = @(
    "", "", "", "", "", "",
    "x", "X", "ii", "i", "oG", "OG", "iTz", "Its", "Im", "The",
    "xX", "Xx", "v", "z", "Mr", "Lil"
)

$mlgFirstWords = @(
    "Ace", "Alpha", "Angry", "Aqua", "Arctic", "Atomic", "Beast", "Big",
    "Blaze", "Blind", "Blue", "Bold", "Boosted", "Brutal", "Chaos", "Chief",
    "Cold", "Cracked", "Crazy", "Dark", "Deadly", "Delta", "Dirty", "Dizzy",
    "Elite", "Epic", "Fast", "Fatal", "Fearless", "Final", "Flash", "Frosty",
    "Golden", "Grim", "Hyper", "Ice", "Insane", "Killer", "Krazy", "Lucky",
    "Mad", "Major", "Mega", "Mighty", "Mint", "Mystic", "Nasty", "Night",
    "Prime", "Pro", "Quick", "Rapid", "Raw", "Red", "Royal", "Savage",
    "Shadow", "Silent", "Slick", "Sneaky", "Speedy", "Steady", "Stormy",
    "Super", "Swift", "Toxic", "True", "Ultra", "Venom", "Vicious", "Wild"
)

$mlgSecondWords = @(
    "Ace", "Beast", "Blaster", "Boss", "Bullet", "Camper", "Captain", "Chief",
    "Clutch", "Cranker", "Crusher", "Demon", "Drifter", "Falcon", "Fighter",
    "Frag", "Gamer", "Ghost", "Grinder", "Gunner", "Hawk", "Hero", "Hunter",
    "Jumper", "Knight", "Legend", "Ninja", "Phantom", "Player", "Predator",
    "Pro", "Raider", "Ranger", "Reaper", "Ripper", "Rival", "Rogue", "Rusher",
    "Savage", "Scope", "Scout", "Shooter", "Slayer", "Sniper", "Soldier",
    "Spartan", "Striker", "Sweat", "Titan", "Trooper", "Viper", "Warrior",
    "Wolf", "Wizard"
)

$mlgSuffixes = @(
    "", "", "", "", "", "", "",
    "x", "X", "z", "HD", "TV", "YT", "OG", "Pro", "JR", "II", "III",
    "7", "13", "21", "24", "27", "33", "47", "69", "99", "117",
    "xX", "Xx"
)

# Smaller pool of believable Xbox-generated-style tags.
$xboxAdjectives = @(
    "Amber", "Ancient", "Brave", "Bright", "Calm", "Clever", "Cosmic", "Daring",
    "Electric", "Flying", "Frozen", "Fuzzy", "Gentle", "Golden", "Grumpy", "Happy",
    "Hidden", "Jolly", "Lucky", "Mighty", "Misty", "Quiet", "Rapid", "Royal",
    "Shiny", "Silent", "Sleepy", "Sneaky", "Spicy", "Swift", "Wandering", "Wild"
)

$xboxNouns = @(
    "Badger", "Banana", "Bear", "Biscuit", "Cactus", "Cupid", "Dolphin", "Dragon",
    "Eagle", "Falcon", "Hamster", "Knight", "Koala", "Lobster", "Moose", "Otter",
    "Panda", "Penguin", "Phoenix", "Potato", "Rabbit", "Raven", "Tiger", "Turtle",
    "Walrus", "Wizard", "Wolf", "Yak"
)

function Get-RandomItem {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [AllowNull()]
        [object[]] $Items
    )

    if ($null -eq $Items -or $Items.Count -eq 0) {
        throw "Get-RandomItem received a null or empty array."
    }

    $index = Get-Random -Minimum 0 -Maximum $Items.Count
    return $Items[$index]
}

function Get-UniqueRandomItem {
    param(
        [Parameter(Mandatory)]
        [object[]] $Items,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.HashSet[string]] $Used,

        [switch] $AllowEmptyRepeat
    )

    # Prefer unused pieces so prefixes/words/suffixes do not visibly repeat.
    $available = @($Items | Where-Object {
        if ($AllowEmptyRepeat -and $_ -eq "") {
            return $true
        }

        return -not $Used.Contains([string] $_)
    })

    # If a pool is ever exhausted, gracefully fall back to the full list.
    if ($available.Count -eq 0) {
        $available = @($Items)
    }

    $choice = [string](Get-RandomItem $available)

    if (-not ($AllowEmptyRepeat -and $choice -eq "")) {
        [void] $Used.Add($choice)
    }

    return $choice
}

function New-TryhardName {
    param(
        [System.Collections.Generic.HashSet[string]] $UsedPrefixes,
        [System.Collections.Generic.HashSet[string]] $UsedSuffixes
    )

    $prefix = Get-UniqueRandomItem -Items $tryhardPrefixes -Used $UsedPrefixes
    $suffix = Get-UniqueRandomItem -Items $tryhardSuffixes -Used $UsedSuffixes
    return "$prefix$suffix"
}

function New-MlgName {
    param(
        [System.Collections.Generic.HashSet[string]] $UsedPrefixes,
        [System.Collections.Generic.HashSet[string]] $UsedFirstWords,
        [System.Collections.Generic.HashSet[string]] $UsedSecondWords,
        [System.Collections.Generic.HashSet[string]] $UsedSuffixes
    )

    $left = Get-UniqueRandomItem -Items $mlgPrefixes -Used $UsedPrefixes -AllowEmptyRepeat
    $first = Get-UniqueRandomItem -Items $mlgFirstWords -Used $UsedFirstWords
    $second = Get-UniqueRandomItem -Items $mlgSecondWords -Used $UsedSecondWords
    $right = Get-UniqueRandomItem -Items $mlgSuffixes -Used $UsedSuffixes -AllowEmptyRepeat

    return "$left$first$second$right"
}

function New-XboxName {
    param(
        [System.Collections.Generic.HashSet[string]] $UsedAdjectives,
        [System.Collections.Generic.HashSet[string]] $UsedNouns
    )

    $adjective = Get-UniqueRandomItem -Items $xboxAdjectives -Used $UsedAdjectives
    $noun = Get-UniqueRandomItem -Items $xboxNouns -Used $UsedNouns
    $number = Get-Random -Minimum 0 -Maximum 1000

    return "$adjective$noun$number"
}

# Build a 17-bot lobby with a controlled mix:
#   4 try-hard aliases
#   10-11 wannabe-MLG names
#   2-3 Xbox-generated-style tags
$xboxCount = Get-Random -Minimum 2 -Maximum 4
$tryhardCount = 4
$mlgCount = 17 - $tryhardCount - $xboxCount

# Keep the four clean try-hard aliases at the top of bots.txt.
# Randomize only the MLG/Xbox names that come after them.
$categories = @(1..$tryhardCount | ForEach-Object { "tryhard" })

$remainingCategories = @()
$remainingCategories += @(1..$mlgCount | ForEach-Object { "mlg" })
$remainingCategories += @(1..$xboxCount | ForEach-Object { "xbox" })
$remainingCategories = @($remainingCategories | Sort-Object { Get-Random })

$categories += $remainingCategories

$usedTryhardPrefixes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$usedTryhardSuffixes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$usedMlgPrefixes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$usedMlgFirstWords = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$usedMlgSecondWords = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$usedMlgSuffixes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$usedXboxAdjectives = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$usedXboxNouns = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

$names = [System.Collections.Generic.List[string]]::new()
$uniqueNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

foreach ($category in $categories) {
    $candidate = $null

    # Retry whole-name collisions, though unique components make them very unlikely.
    for ($attempt = 0; $attempt -lt 50; $attempt++) {
        switch ($category) {
            "tryhard" {
                $candidate = New-TryhardName `
                    -UsedPrefixes $usedTryhardPrefixes `
                    -UsedSuffixes $usedTryhardSuffixes
            }
            "mlg" {
                $candidate = New-MlgName `
                    -UsedPrefixes $usedMlgPrefixes `
                    -UsedFirstWords $usedMlgFirstWords `
                    -UsedSecondWords $usedMlgSecondWords `
                    -UsedSuffixes $usedMlgSuffixes
            }
            "xbox" {
                $candidate = New-XboxName `
                    -UsedAdjectives $usedXboxAdjectives `
                    -UsedNouns $usedXboxNouns
            }
            default {
                throw "Unknown bot-name category: $category"
            }
        }

        if ($uniqueNames.Add($candidate)) {
            [void] $names.Add($candidate)
            break
        }
    }

    if ($names.Count -lt ($uniqueNames.Count)) {
        throw "Failed to generate a unique bot name."
    }
}

if ($names.Count -ne 17) {
    throw "Expected 17 bot names but generated $($names.Count)."
}

# Save a copy beside this PowerShell script so you can inspect the launch's names.
$scriptDirectory = Split-Path -Parent $PSCommandPath
$localBotsFile = Join-Path $scriptDirectory "bots.txt"

[System.IO.File]::WriteAllLines(
    $localBotsFile,
    [string[]] $names,
    [System.Text.Encoding]::ASCII
)

$tempFolder = Join-Path $env:TEMP "iw5-random-bot-names"
$botsFile = Join-Path $tempFolder "bots.txt"

New-Item -ItemType Directory -Force -Path $tempFolder | Out-Null

# ASCII avoids encoding surprises in older game assets.
[System.IO.File]::WriteAllLines(
    $botsFile,
    [string[]] $names,
    [System.Text.Encoding]::ASCII
)

Write-Host "Generated bot names ($tryhardCount try-hard, $mlgCount wannabe-MLG, $xboxCount Xbox-style):"
$names | ForEach-Object { Write-Host "  $_" }

# Delete the old bots.txt from the archive, then add the new one at archive root.
& $winRar d -ibck $iwdPath "bots.txt" | Out-Null
& $winRar a -ibck -ep $iwdPath $botsFile | Out-Null

if ($LASTEXITCODE -ne 0) {
    throw "WinRAR failed to update the IWD."
}

Write-Host ""
Write-Host "Updated: $iwdPath"
Write-Host "You can now launch Plutonium."
